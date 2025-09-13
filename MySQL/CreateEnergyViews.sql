USE Expenditure;

DROP VIEW IF EXISTS WeeklyFuel;

CREATE VIEW WeeklyFuel AS
SELECT 
	J1.Date AS Start, 
	J2.Date AS End, 
	J1.PumpPrice 
FROM (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date) Num, 
	    Date,
		PumpPrice
    FROM Expenditure.WeeklyFuelPrices) AS J1
LEFT OUTER JOIN (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date ) Num, 
		Date
	FROM Expenditure.WeeklyFuelPrices) J2
ON J2.Num = J1.Num + 1;

DROP VIEW IF EXISTS Chargers;

CREATE VIEW Chargers AS
SELECT
	CL.Name,
    CL.Provider,
--  xx  CL.Tariff,
    CL.Location,
    COALESCE(CU.Rate, CL.Rate) AS Rate,
    CP.Name  AS Network,
	CU.Name  AS Unit,
	CU.Active,
    CL.Comment
FROM Expenditure.ChargerLocation CL
LEFT JOIN Expenditure.ChargerUnit CU
ON CU.Location = CL.Name
LEFT JOIN Expenditure.Company CP
ON CL.Provider = CP.Id;

DROP VIEW IF EXISTS MergedSession;

CREATE VIEW MergedSession AS
SELECT
 CarReg,
 Mileage,
 Min(Start)        AS Start,
 Max(End)          AS End,
 Count(*)          AS Sessions,
 Min(Charger)      AS Charger,
 SUM(Charge)       AS Charge,
 SUM(Cost)         AS Cost,
 Min(StartMiles)   AS StartMiles,
 Max(EndMiles)     AS EndMiles,
 Min(StartPercent) AS StartPercent,
 Max(EndPercent)   AS EndPercent,
 Max(Start)        AS High,
 Max(Charger)      AS MaxCharger,
 Min(Unit)         AS MinUnit,
 Max(Unit)         AS MaxUnit,
 Min(Charge)       AS MinCharge,
 Max(Charge)       AS MaxCharge,
 Min(Cost)         AS MinCost,
 Max(Cost)         AS MaxCost
 FROM expenditure.chargesession
 GROUP BY CarReg, Mileage;
 
DROP VIEW IF EXISTS BoundedChargeSession;

CREATE VIEW BoundedChargeSession AS
SELECT
	MS.CarReg,
    MS.Start,
    YEAR(MS.Start)    AS Year,
    MONTH(MS.Start)   AS Month,
    WEEK(MS.Start, 1) AS Week,
    MS.Mileage,
    MS.Charger,
    MS.Sessions,
    MS.MinUnit    AS Unit,
    MS.StartPercent,
    MS.EndPercent,
    CS.UsedMiles,
    CS.UsedPercent,
    MS.Cost,
    MS.Charge,
    ROUND((MS.EndPercent - MS.StartPercent) * Car.Capacity / 100, 2) AS EstCharge,
    COALESCE(MS.Charge, ROUND((MS.EndPercent - MS.StartPercent) * Car.Capacity / 100, 2)) AS UseCharge,
    TF.UnitRate,
    Car.Capacity,
    Car.MilesPerLitre,
    WF.PumpPrice
FROM MergedSession MS
JOIN (
	SELECT 
		J1.CarReg,
        J1.Start,
        J2.Mileage    - J1.Mileage      AS UsedMiles,
        J1.EndPercent - J2.StartPercent AS UsedPercent
	FROM (
    SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, Start) Num,
		CarReg,
        Start,
        EndPercent,
		StartPercent,
		Mileage
    FROM Expenditure.MergedSession) AS J1
    JOIN (
    SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, Start) Num,
		CarReg,
        Start,
		StartPercent,
		Mileage
    FROM Expenditure.MergedSession) AS J2
    ON  J1.CarReg = J2.CarReg
    AND J1.Num    = J2.num - 1) CS
ON MS.CarReg = CS.CarReg
AND MS.Start = CS.Start
JOIN Expenditure.ChargerLocation CL
ON  MS.Charger = CL.Name
LEFT JOIN Expenditure.Tariff TF
ON   TF.Type   = 'Electric' 
AND  MS.Start  > TF.Start 
AND (MS.End    < TF.End OR TF.End IS NULL)
JOIN Expenditure.Car
ON  Car.Registration = MS.CarReg
JOIN Expenditure.WeeklyFuel WF
ON        MS.Start  >= WF.Start 
AND      (MS.Start  < WF.End OR WF.End IS NULL);

DROP VIEW IF EXISTS SessionUsage;

CREATE VIEW SessionUsage AS
SELECT 
	CarReg,
	Start,
    Year,
    Month,
    Week,
    Mileage,
    Charger,
    Unit,
    Cost,
    Charge,
    EstCharge,
    StartPercent,
    EndPercent,
    UseCharge,
    UsedMiles,
    UsedPercent,
    ROUND(UsedPercent * Capacity / 100, 2)                  AS UsedCharge,            
    ROUND(UseCharge * UnitRate / 100, 2)                    AS HomeCost,
    ROUND(Cost - UseCharge * UnitRate / 100 , 2)            AS HomeCostDiff,
    ROUND(UsedMiles / MilesPerLitre * PumpPrice / 100, 2)   AS PetrolCost,
    ROUND(UsedPercent * Capacity / 100 * UnitRate / 100, 2) AS UsedHomeCost,
    ROUND(100 * EstCharge / UseCharge, 1)                   AS Efficiency
FROM expenditure.boundedchargesession;

DROP VIEW IF EXISTS SessionLog;																															

CREATE VIEW SessionLog AS
SELECT
    CASE WHEN CS.Unit = '' THEN CS.Charger ELSE CS.Unit END AS Device,
    J2.CarReg,
    J2.Session,
	J2.Timestamp,
    J2.Percent,
    J2.Miles,
    CASE
      WHEN J1.Miles IS NULL THEN 
        0
      ELSE 
		CAST(J2.Miles - J1.Miles AS DECIMAL)
      END AS MilesAdded,
    CASE
      WHEN J1.Percent IS NULL THEN 
        0
      ELSE 
		CAST(J2.Percent - J1.Percent AS DECIMAL)
      END AS PercentGain,
	CASE
      WHEN J1.Timestamp IS NULL THEN 
        0
      ELSE
		ROUND(TIMESTAMPDIFF(Second, J1.Timestamp, J2.Timestamp) / 60, 2)
      END AS TimeTaken
FROM (
	SELECT 
		CarReg,
		Timestamp,
        Session,
        Miles,
        Percent,
		ROW_NUMBER() OVER (PARTITION BY CarReg, Session ORDER BY Timestamp) AS SeqNo
	FROM ChargeSessionLog) AS J1
RIGHT OUTER JOIN (
	SELECT 
		CarReg,
		Timestamp,
        Session,
        Miles,
        Percent,
		ROW_NUMBER() OVER (PARTITION BY CarReg, Session ORDER BY Timestamp) AS SeqNo
	FROM ChargeSessionLog) AS J2
	ON  J1.SeqNo  = J2.SeqNo - 1
	AND J1.CarReg = J2.CarReg
    AND J1.Session = J2.Session
JOIN ChargeSession CS
    ON J2.CarReg   = CS.CarReg
    AND J2.Session = CS.Start;

DROP VIEW IF EXISTS SessionLogSummary;

CREATE VIEW SessionLogSummary AS
SELECT
    Min(CS.Start)        AS Session,
    Min(CS.Charger)      AS Charger,
    Min(CS.Unit)         AS Unit,
    Min(CS.StartMiles)   AS StartMiles,
    Min(CS.StartPerCent) AS StartPercent,
    Min(CS.Charge)       AS Charge,
    Min(CL.Timestamp)    AS StartTime,
    Min(CL.Miles)        AS LogStartMile,
    Sum(CL.MilesAdded)   AS MilesAdded,
    Sum(CL.TimeTaken)    AS TimeTaken
FROM expenditure.chargesession CS
JOIN expenditure.sessionlog    CL
ON  CS.CarReg      =  CL.CarReg
AND CS.Start       =  CL.Session
AND CS.Start      <> CL.Timestamp
AND CL.MilesAdded <= 1
GROUP BY CS.Start;

DROP VIEW IF EXISTS BoundedReading;

CREATE VIEW BoundedReading AS
SELECT
	J1.Timestamp                         AS Start,
    J1.Identifier                        AS Meter,
    J1.Type,
    J1.Weekday,
    J2.Timestamp                         AS 'End',
    DATEDIFF(J2.Timestamp, J1.Timestamp) AS Days,
    J1.Reading                           AS StartReading,
    J2.Reading                           AS EndReading,
    J1.SeqNo,
    J2.Reading - J1.Reading              AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        UnitsToKwhByDate(J2.TruncReading - J1.TruncReading, J1.Timestamp)
      ELSE 
		J2.TruncReading - J1.TruncReading
      END AS Kwh,
    J1.Tariff,
    TR.UnitRate,
    TR.OffPeakRate,
    TR.StandingCharge,
    GetCalorificValue(J1.Timestamp) AS CalorificValue,
    J1.Comment
FROM (
SELECT 
		Timestamp,
        Weekday,
        MT.Identifier,
        MT.Type,
        MRT.Tariff,
        Reading,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
        MR.Comment
	FROM MeterReading MR
    JOIN Meter AS MT
    ON  MR.Meter    = MT.Identifier 
    AND MR.Timestamp >= MT.Installed
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)
    JOIN MeterReadingTariff MRT
    ON MRT.Meter      = MT.Identifier
    AND MR.Timestamp >= MRT.Start
    AND (MRT.End IS NULL OR MR.Timestamp < MRT.End)) AS J1
JOIN (
SELECT 
		Timestamp,
        Weekday,
        MT.Identifier,
        MT.Type,
        Reading,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
        MR.Comment
	FROM MeterReading MR
    JOIN Meter AS MT
    ON  MR.Meter      = MT.Identifier 
    AND MR.Timestamp >= MT.Installed
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)) AS J2
	ON J1.SeqNo       = J2.SeqNo - 1
    AND J1.Identifier = J2.Identifier
	AND J1.Type       = J2.Type
LEFT JOIN Tariff  TR 
ON   J1.Timestamp >= TR.Start 
AND (J1.Timestamp <  TR.End OR TR.End IS NULL)
AND TR.Code        = J1.Tariff
AND TR.Type        = J1.Type;

DROP VIEW IF EXISTS CostedReading;

CREATE VIEW CostedReading AS
SELECT 
	BR.*,
    OP.OPKwh                                                            AS OffPeakKwh,    
    BR.Kwh - OPKwh                                                      AS PeakKwh,
    ROUND(UnitRate * Kwh / 100, 2)                                      AS KwhCost,
    ROUND(Days * StandingCharge / 100, 2)                               AS StdCost,
    ROUND(UnitRate * (Kwh - OPKwh) / 100, 2)                            AS PeakKwhCost,
    COALESCE(ROUND(OffPeakRate * OPKwh / 100, 2), 0)                    AS OffPeakKwhCost,
    ROUND((UnitRate * (Kwh - OPKwh) + 
           COALESCE(OffPeakRate * OPKwh, 0) + 
           Days * StandingCharge) / 100, 2)                             AS TotalCost,
           COALESCE(ROUND((UnitRate -OffPeakRate) * OPKwh / 100, 2), 0) AS OffPeakSaving
FROM BoundedReading BR
JOIN  (
	SELECT
		BRI.Meter,
		Start,
		COALESCE(Count(*), 0)     AS Count,
		COALESCE(Sum(OPI.Kwh), 0) AS OPKwh
	FROM BoundedReading BRI
	LEFT JOIN MeterOffpeak   OPI
	ON  BRI.Meter = OPI.Meter
	AND OPI.Timestamp >= BRI.Start AND OPI.Timestamp < BRI.End
	GROUP BY BRI.Meter, Start ) OP
ON  BR.Meter = OP.Meter
AND BR.Start = OP.Start;


DROP VIEW IF EXISTS BoundedReadingMon;

CREATE VIEW BoundedReadingMon AS
SELECT
	J1.Timestamp                         AS Start,
    J1.Identifier                        AS Meter,
    J1.Type,
    J1.Weekday,
    J2.Timestamp                         AS 'End',
    DATEDIFF(J2.Timestamp, J1.Timestamp) AS Days,
    J1.Reading                           AS StartReading,
    J2.Reading                           AS EndReading,
    J1.SeqNo,
    J2.Reading - J1.Reading              AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        UnitsToKwhByDate(J2.TruncReading - J1.TruncReading, J1.Timestamp)
      ELSE 
		J2.TruncReading - J1.TruncReading
      END AS Kwh,
    J1.Tariff,
    TR.UnitRate,
    TR.OffPeakRate,
    TR.StandingCharge,
    GetCalorificValue(J1.Timestamp) AS CalorificValue,
    J1.Comment
FROM (
SELECT 
		Timestamp,
        Weekday,
        MT.Identifier,
        MT.Type,
        MRT.Tariff,
        Reading,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
        MR.Comment
	FROM MeterReading MR
    JOIN Meter AS MT
    ON  MR.Meter    = MT.Identifier 
    AND MR.Timestamp >= MT.Installed
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)
    JOIN MeterReadingTariff MRT
    ON MRT.Meter      = MT.Identifier
    AND MR.Timestamp >= MRT.Start
    AND MR.WeekDay    = 'Mon'
    AND (MRT.End IS NULL OR MR.Timestamp < MRT.End)) AS J1
JOIN (
SELECT 
		Timestamp,
        Weekday,
        MT.Identifier,
        MT.Type,
        Reading,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
        MR.Comment
	FROM MeterReading MR
    JOIN Meter AS MT
    ON  MR.Meter      = MT.Identifier 
    AND MR.Timestamp >= MT.Installed
    AND MR.WeekDay    = 'Mon'
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)) AS J2
	ON J1.SeqNo       = J2.SeqNo - 1
    AND J1.Identifier = J2.Identifier
	AND J1.Type       = J2.Type
LEFT JOIN Tariff  TR 
ON   J1.Timestamp >= TR.Start 
AND (J1.Timestamp <  TR.End OR TR.End IS NULL)
AND TR.Code        = J1.Tariff
AND TR.Type        = J1.Type;

DROP VIEW IF EXISTS CostedReadingMon;

CREATE VIEW CostedReadingMon AS
SELECT 
	BR.*,
    OP.OPKwh                                                            AS OffPeakKwh,    
    BR.Kwh - OPKwh                                                      AS PeakKwh,
    ROUND(UnitRate * Kwh / 100, 2)                                      AS KwhCost,
    ROUND(Days * StandingCharge / 100, 2)                               AS StdCost,
    ROUND(UnitRate * (Kwh - OPKwh) / 100, 2)                            AS PeakKwhCost,
    COALESCE(ROUND(OffPeakRate * OPKwh / 100, 2), 0)                    AS OffPeakKwhCost,
    ROUND((UnitRate * (Kwh - OPKwh) + 
           COALESCE(OffPeakRate * OPKwh, 0) + 
           Days * StandingCharge) / 100, 2)                             AS TotalCost,
           COALESCE(ROUND((UnitRate -OffPeakRate) * OPKwh / 100, 2), 0) AS OffPeakSaving
FROM BoundedReadingMon BR
JOIN  (
	SELECT
		BRI.Meter,
		Start,
		COALESCE(Count(*), 0)     AS Count,
		COALESCE(Sum(OPI.Kwh), 0) AS OPKwh
	FROM BoundedReading BRI
	LEFT JOIN MeterOffpeak   OPI
	ON  BRI.Meter = OPI.Meter
	AND OPI.Timestamp >= BRI.Start AND OPI.Timestamp < BRI.End
	GROUP BY BRI.Meter, Start ) OP
ON  BR.Meter = OP.Meter
AND BR.Start = OP.Start;

DROP VIEW IF EXISTS SessionChargeDetails;

CREATE VIEW SessionChargeDetails AS
SELECT
	CarReg,
    Start,
    End,
    Charger,
    60 * EstDuration                                                   AS EstDuration,
    StartPercent,
    EndPercent,
    EndPercent - StartPerCent                                          AS PercentGain,
    Charge,
    CASE  WHEN  ChargeDuration IS NULL THEN 'Y' ELSE 'N' END           AS DurationCalculated,
    COALESCE(ChargeDuration, TIMEDIFF(End, Start))                     AS ChargeDuration,
    TIME_TO_SEC(COALESCE(ChargeDuration, TIMEDIFF(End, Start))) / 60.0 AS ChargeDurationMinutes
FROM ChargeSession;

DROP VIEW IF EXISTS SmartMeterHourlyData;

CREATE VIEW SmartMeterHourlyData AS
SELECT
	Date,
    Hour,
    Year(Date)                  AS Year,
    WEEK(Date, 3)               AS Week,
    SUBSTR(DAYNAME(Date), 1, 3) AS Weekday,
    Type,
    
    Min(Peak) AS Peak,
    SUM(Reading) AS Reading
FROM (
	SELECT 
		DATE(End)  AS Date,
		HOUR(End)  AS Hour,
        Type,
		CASE 
			WHEN Type = 'Electric' AND HOUR(End) BETWEEN 0 AND 4 THEN 
				'N'
			WHEN Type = 'Electric' AND HOUR(End) BETWEEN 5 AND 24 THEN 
				'Y'
			ELSE null
		END AS Peak,
        Reading
	FROM Expenditure.SmartMeterUsageData) UD
    GROUP BY Date, Hour, Type;
    
DROP VIEW IF EXISTS SmartMeterDailyData;

CREATE VIEW SmartMeterDailyData AS
    SELECT
	AL.Date,
    AL.Type,
    AL.WeekDay,
    AL.Hours,
    AL.ReadingChange,
    Coalesce(OP.Hours, 0)         AS OPHours,
    Coalesce(Op.ReadingChange, 0) AS OPReadingChange
FROM (
	SELECT 
		Date,
		Type,
		Count(*)     AS Hours,
		Min(Weekday) AS WeekDay,
		Sum(Reading) AS ReadingChange
	FROM Expenditure.SmartMeterHourlyData
	GROUP BY  Date, Type) AL
LEFT JOIN (
	SELECT 
		Date,
		Type,
		Count(*)     AS Hours,
		Min(Weekday) AS WeekDay,
		Sum(Reading) AS ReadingChange
	FROM Expenditure.SmartMeterHourlyData
	WHERE Peak = 'N'
	GROUP BY  Date, Type) OP
ON  AL.Date = OP.Date
AND AL.Type = OP.TYpe;

DROP VIEW IF EXISTS BoundedCalorificValue;

CREATE VIEW BoundedCalorificValue AS
SELECT 
	J1.Date   AS Start,
    J2.Date   AS End,
    J1.Value  AS Value
FROM (    
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date) Num, 
	    Date,
		Value
    FROM Expenditure.CalorificValue) J1	
	LEFT OUTER JOIN (
	SELECT 
		Date,
		ROW_NUMBER ( ) OVER (ORDER BY Date ) Num,
        Value
	FROM Expenditure.CalorificValue) J2
ON J2.Num = J1.Num + 1;

DROP VIEW IF EXISTS SmartMeterUsageKwh;

CREATE VIEW SmartMeterUsageKwh AS
SELECT 
	Start,
    End,
    Type,
    Year(Start)      AS Year,
    DayOfYear(Start) AS Day,
    Hour(Start)      AS Hour,
    Month(Start)     AS Month,
    Week(Start)      AS Week,
    Weekday,
    Reading,    
    CASE
      WHEN Type = 'Gas' THEN 
        UnitsToKwhByDate(Reading, Start)
      ELSE 
        Reading
	  END AS Kwh,
      Comment
    FROM Expenditure.SmartMeterUsageData;

DROP VIEW IF EXISTS SolarReadings;

CREATE VIEW SolarReadings AS    
SELECT 
	J1.Timestamp            AS Start,
    J2.Timestamp            AS End,
    'Solar'                 AS Type,
    Year(J1.Timestamp)      AS Year,
    DayOfYear(J1.Timestamp) AS Day,
    Hour(J1.Timestamp)      AS Hour,
    Month(J1.Timestamp)     AS Month,
    Week(J1.Timestamp)      AS Week,
    DATEDIFF(J2.Timestamp, J1.Timestamp) AS Days,
    J1.Reading  AS StartReading,
    J2.Reading - J1.Reading AS Kwh,
	CAST((J2.Reading - J1.Reading) / DATEDIFF(J2.Timestamp, J1.Timestamp) AS DECIMAL(10, 2)) AS KwhPerDay
FROM (
	SELECT
		Timestamp,
		ROW_NUMBER () OVER (ORDER BY Timestamp) Num,
        CAST(Reading AS DECIMAL(10, 1)) AS Reading
	FROM expenditure.meterreading MR
	JOIN expenditure.meter        MT
	ON MR.Meter = MT.Identifier
	WHERE MT.Type = 'Solar' AND Reading IS NOT NULL AND (MR.Status <> 'Ignore' OR MR.Status IS NULL)) J1
JOIN (
	SELECT
		Timestamp,
		ROW_NUMBER () OVER (ORDER BY Timestamp) Num,
        CAST(Reading AS DECIMAL(10, 1)) AS Reading
	FROM expenditure.meterreading MR
	JOIN expenditure.meter        MT
	ON MR.Meter = MT.Identifier
	WHERE MT.Type = 'Solar' AND Reading IS NOT NULL AND (MR.Status <> 'Ignore' OR MR.Status IS NULL)) J2
ON J1.NUM + 1 = J2.Num;


DROP VIEW IF EXISTS SolarExportData;

CREATE VIEW SolarExportData AS    
SELECT 
	SR.Start,
    Max(SR.End)                                                      AS End,
    Min(Days)                                                        AS Days,
    Min(Kwh)                                                         AS Kwh,
    SUM(SD.Reading)                                                  AS KwhExported,
    Min(Kwh) - SUM(SD.Reading)                                       AS KwhUsed,
    CAST(100 * SUM(SD.Reading) / Min(Kwh)         AS DECIMAL(10, 2)) AS `%Exported`,                                                   
    CAST(Min(Kwh) / Min(Days)                     AS DECIMAL(10, 3)) AS KwhPerDay,
    CAST(SUM(SD.Reading) / Min(Days)              AS DECIMAL(10, 3)) AS KwhExportedPerDay,
    CAST((Min(Kwh) - SUM(SD.Reading)) / Min(Days) AS DECIMAL(10, 3)) AS KwhUsedPerDay
FROM expenditure.solarreadings SR
JOIN expenditure.smartmeterusagedata SD
ON SD.Start BETWEEN SR.Start AND SR.End AND SD.Type = 'Export'
GROUP BY Start
ORDER BY Start;