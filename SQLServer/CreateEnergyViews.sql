USE Expenditure
GO

DROP VIEW IF EXISTS WeeklyFuel
GO

CREATE VIEW WeeklyFuel AS
SELECT 
	J1.Date AS Start, 
	J2.Date AS [End], 
	J1.PumpPrice 
FROM (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date) Num, 
	    Date,
		PumpPrice
    FROM Expenditure.dbo.WeeklyFuelPrices) AS J1
LEFT OUTER JOIN (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date ) Num, 
		Date
	FROM Expenditure.dbo.WeeklyFuelPrices) J2
ON J2.Num = J1.Num + 1
GO

DROP VIEW IF EXISTS  Chargers
GO

CREATE VIEW Chargers AS
SELECT
	CL.Name,
    CL.Provider,
    CL.Location,
    COALESCE(CU.Rate, CL.Rate) AS Rate,
    CP.Name                    AS Network,
	CU.Name                    AS Unit,
	CU.Active,
    CL.Comment
FROM ChargerLocation  CL
LEFT JOIN ChargerUnit CU
ON CU.Location = CL.Name
LEFT JOIN Company CP
ON CL.Provider = CP.Id
GO

DROP VIEW IF EXISTS MergedSession
GO

CREATE VIEW MergedSession AS
SELECT
	CarReg,
	Mileage,
	Min(Start)        AS Start,
	Max([End])        AS [End],
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
 FROM ChargeSession
 GROUP BY CarReg, Mileage
GO

DROP VIEW IF EXISTS BoundedChargeSession;
GO

CREATE VIEW BoundedChargeSession AS
SELECT
	MS.CarReg,
    MS.Start,
    YEAR(MS.Start)               AS Year,
    MONTH(MS.Start)              AS Month,
	DATEPART(ISO_WEEK, MS.Start) AS Week,
    MS.Mileage,
    MS.Charger,
    MS.Sessions,
    MS.MinUnit                   AS Unit,
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
    FROM MergedSession) AS J1
    JOIN (
    SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, Start) Num,
		CarReg,
        Start,
		StartPercent,
		Mileage
    FROM MergedSession) AS J2
    ON  J1.CarReg = J2.CarReg
    AND J1.Num    = J2.num - 1) CS
ON MS.CarReg = CS.CarReg
AND MS.Start = CS.Start
JOIN ChargerLocation CL
ON  MS.Charger = CL.Name
LEFT JOIN Tariff TF
ON        TF.Type   = 'Electric' 
AND       MS.Start  > TF.Start 
AND      (MS.[End]    < TF.[End] OR TF.[End] IS NULL)
JOIN Car
ON Car.Registration = MS.CarReg
JOIN WeeklyFuel WF
ON        MS.Start  >= WF.Start 
AND      (MS.Start  < WF.[End] OR WF.[End] IS NULL)
GO

DROP VIEW IF EXISTS SessionUsage
GO

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
FROM BoundedChargeSession
GO
    
DROP VIEW IF EXISTS SessionLog;
GO

CREATE VIEW SessionLog AS
SELECT
    CASE WHEN CS.Unit = '' THEN CS.Charger ELSE CS.Unit END AS Device,
    J2.CarReg,
	J2.Timestamp,
    J2.Session,
    J2.[Percent],
    J2.Miles,
    CASE
      WHEN J1.Miles IS NULL THEN 
        0
      ELSE 
		J2.Miles - J1.Miles
      END AS MilesAdded,
    CASE
      WHEN J1.[Percent] IS NULL THEN 
        0
      ELSE 
		J2.[Percent] - J1.[Percent]
      END AS PercentGain,
	CASE
      WHEN J1.Timestamp IS NULL THEN 
        0
      ELSE
		CAST(DATEDIFF(ss, J1.Timestamp, J2.Timestamp) / 60 AS DECIMAL(9, 2))
      END AS TimeTaken
FROM (
	SELECT 
		CarReg,
		Timestamp,
        Session,
        Miles,
        [Percent],
		ROW_NUMBER() OVER (PARTITION BY CarReg, Session ORDER BY Timestamp) AS SeqNo
	FROM ChargeSessionLog) AS J1
RIGHT OUTER JOIN (
	SELECT 
		CarReg,
		Timestamp,
        Session,
        Miles,
        [Percent],
		ROW_NUMBER() OVER (PARTITION BY CarReg, Session ORDER BY Timestamp) AS SeqNo
	FROM ChargeSessionLog) AS J2
	ON  J1.SeqNo   = J2.SeqNo - 1
	AND J1.CarReg  = J2.CarReg
    AND J1.Session = J2.Session
JOIN ChargeSession CS
    ON J2.CarReg   = CS.CarReg
    AND J2.Session = CS.Start;
GO

DROP VIEW IF EXISTS SessionLogSummary;
GO

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
FROM ChargeSession CS
JOIN SessionLog    CL
ON  CS.CarReg      =  CL.CarReg
AND CS.Start       =  CL.Session
AND CS.Start      <> CL.Timestamp
AND CL.MilesAdded <= 1
GROUP BY CS.Start
GO

DROP VIEW IF EXISTS BoundedReading
GO

CREATE VIEW BoundedReading AS
SELECT
	J1.Timestamp                              AS Start,
    J1.Identifier                             AS Meter,
    J1.Type,
    J1.Weekday,
    J2.Timestamp                              AS 'End',
    DATEDIFF(Day, J1.Timestamp, J2.Timestamp) AS Days,
    J1.Reading                                AS StartReading,
    J2.Reading                                AS EndReading,
    J1.SeqNo,
    J2.Reading - J1.Reading                   AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        dbo.UnitsToKwhByDate(J2.TruncReading - J1.TruncReading, J1.Timestamp)
      ELSE 
		J2.TruncReading - J1.TruncReading
      END                                     AS Kwh,
    TR.UnitRate,
	TR.OffPeakRate,
    TR.StandingCharge,
    dbo.GetCalorificValue(J1.Timestamp) AS CalorificValue,
    J1.Comment
FROM (
	SELECT 
		Timestamp,
        Weekday,
		MT.Identifier,
        MT.Type,
        MRT.Tariff,
        Reading,
        ROUND(Reading, 0)                                                    AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
        MR.Comment
	FROM MeterReading MR
	JOIN Meter  AS MT
	ON  MR.Meter      = MT.Identifier
    AND MR.Timestamp >= MT.Installed
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)
    JOIN MeterReadingTariff MRT
    ON MRT.Meter      = MT.Identifier
    AND MR.Timestamp >= MRT.Start
    AND (MRT.[End] IS NULL OR MR.Timestamp < MRT.[End])) AS J1
JOIN (
	SELECT 
		Timestamp,
		WeekDay,
		MT.Identifier,
        MT.Type,
        Reading,
        ROUND(Reading, 0)                                                    AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
		MR.Comment
	FROM MeterReading MR
	JOIN Meter  AS MT
    ON  MR.Meter      = MT.Identifier 
    AND MR.Timestamp >= MT.Installed
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)) AS J2
	ON J1.SeqNo       = J2.SeqNo - 1
	AND J1.Type       = J2.Type
	AND J1.Identifier = J2.Identifier
LEFT JOIN Tariff  TR 
ON   J1.Timestamp >= TR.Start 
AND (J1.Timestamp <  TR.[End] OR TR.[End] IS NULL)
AND TR.Code       =  J1.Tariff
AND TR.Type       =  J1.Type

GO

DROP VIEW IF EXISTS CostedReading
GO

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
	LEFT JOIN  MeterOffPeak   OPI
	ON  BRI.Meter = OPI.Meter
	AND OPI.Timestamp BETWEEN BRI.Start AND BRI.[End]
	GROUP BY BRI.Meter, Start ) OP
ON  BR.Meter = OP.Meter
AND BR.Start = OP.Start
GO

DROP VIEW IF EXISTS SessionChargeDetails
GO

CREATE VIEW SessionChargeDetails AS
SELECT
	CarReg,
    Start,
    [End],
    Charger,
	60 * EstDuration                                           AS EstDuration,
    StartPercent,
    EndPercent,
    EndPercent - StartPerCent                                  AS PercentGain,
    Charge,
    CASE  WHEN  ChargeDuration IS NULL THEN 'Y' ELSE 'N' END   AS DurationCalculated,
    COALESCE(ChargeDuration, CAST(([End] - Start) AS TIME(0))) AS ChargeDuration,
	DATEDIFF(SECOND, '1/1/1900', CONVERT(DATETIME, COALESCE(ChargeDuration, CAST(([End] - Start) AS TIME(0))))) / 60.0 AS ChargeDurationMinutes
FROM ChargeSession;
GO

DROP VIEW IF EXISTS BoundedCalorificValue
GO

CREATE VIEW BoundedCalorificValue AS
SELECT 
	J1.Date  AS Start,
    J2.Date  AS [End],
    J2.Value AS Value
FROM (    
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date) Num, 
	    Date,
		Value
    FROM CalorificValue) J1	
	LEFT OUTER JOIN (
	SELECT 
		Date,
		ROW_NUMBER ( ) OVER (ORDER BY Date ) Num,
        Value
	FROM CalorificValue) J2
ON J2.Num = J1.Num + 1
GO

DROP VIEW IF EXISTS SmartMeterHourlyData;
GO

CREATE VIEW SmartMeterHourlyData AS
SELECT
	Date,
    Hour,
    Year(Date)                              AS Year,
    DATEPART(week, Date)                    AS Week,
	SUBSTRING(DATENAME(weekday, Date),1, 3) AS Weekday,
    Type,    
    Min(Peak)                               AS Peak,
    SUM(Reading)                            AS Reading
FROM (
	SELECT 
		CAST([End] AS Date)   AS Date,
		DATEPART(hour, [End]) AS Hour,
        Type,
		CASE 
			WHEN Type = 'Electric' AND DATEPART(hour, [End]) BETWEEN 0 AND 4 THEN 
				'N'
			WHEN Type = 'Electric' AND DATEPART(hour, [End]) BETWEEN 5 AND 24 THEN 
				'Y'
			ELSE null
		END AS Peak,
        Reading
	FROM SmartMeterUsageData) UD
    GROUP BY Date, Hour, Type;
 GO
 
DROP VIEW IF EXISTS SmartMeterDailyData;
GO

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
	FROM SmartMeterHourlyData
	GROUP BY  Date, Type) AL
LEFT JOIN (
	SELECT 
		Date,
		Type,
		Count(*)     AS Hours,
		Min(Weekday) AS WeekDay,
		Sum(Reading) AS ReadingChange
	FROM SmartMeterHourlyData
	WHERE Peak = 'N'
	GROUP BY  Date, Type) OP
ON  AL.Date = OP.Date
AND AL.Type = OP.TYpe;
GO

DROP VIEW IF EXISTS SmartMeterUsageKwh
GO

CREATE VIEW SmartMeterUsageKwh AS
SELECT 
	Start,
    [End],
    Type,
    [Weekday],
    Reading,    
    CASE
      WHEN Type = 'Gas' THEN 
        dbo.UnitsToKwhByDate(Reading, Start)
      ELSE 
        Reading
	  END Kwh,
      Comment
FROM SmartMeterUsageData
GO