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
    CL.Tariff,
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
    TD.UnitRate AS DefaultUnitRate,
    COALESCE(TF.UnitRate, TD.UnitRate) AS UseRate,
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
ON        CL.Tariff = TF.Code 
AND       TF.Type   = 'Electric' 
AND       MS.Start  > TF.Start 
AND      (MS.[End]    < TF.[End] OR TF.[End] IS NULL)
JOIN Car
ON Car.Registration = MS.CarReg
LEFT JOIN Tariff TD
ON        Car.DefaultTariff = TD.Code 
AND       TD.Type    = 'Electric' 
AND       MS.Start  >= TD.Start 
AND      (MS.Start  < TD.[End] OR TD.[End] IS NULL)
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
    ROUND(UsedPercent * Capacity / 100, 2)                 AS UsedCharge,            
    ROUND(UseCharge * UseRate / 100, 2)                    AS HomeCost,
    ROUND(Cost - UseCharge * UseRate / 100 , 2)            AS HomeCostDiff,
    ROUND(UsedMiles / MilesPerLitre * PumpPrice / 100, 2)  AS PetrolCost,
    ROUND(UsedPercent * Capacity / 100 * UseRate / 100, 2) AS UsedHomeCost,
    ROUND(100 * EstCharge / UseCharge, 1)                  AS Efficiency
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
    J1.Estimated                              AS StartEstimated,
    J1.Weekday,
    J2.Timestamp                              AS 'End',
    J2.Estimated                              AS EndEstimated,
    DATEDIFF(Day, J1.Timestamp, J2.Timestamp) AS Days,
    J1.Reading                                AS StartReading,
    J2.Reading                                AS EndReading,
    J1.SeqNo,
    J2.Reading - J1.Reading                   AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        dbo.UnitsToKwh(J2.TruncReading - J1.TruncReading, TR.CalorificValue)
      ELSE 
		J2.TruncReading - J1.TruncReading
      END AS Kwh,
    J1.Tariff,
    TR.UnitRate,
    TR.StandingCharge,
    TR.CalorificValue,
    J1.Comment
FROM (
	SELECT 
		Timestamp,
        Weekday,
		MT.Identifier,
        MT.Type,
        Tariff,
        Reading,
        Estimated,
        ROUND(Reading, 0)                                                    AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
        MR.Comment
	FROM MeterReading MR
	JOIN Meter  AS MT
	ON  MR.Meter      = MT.Identifier
    AND MR.Timestamp >= MT.Installed
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)) AS J1
JOIN (
	SELECT 
		Timestamp,
		WeekDay,
		MT.Identifier,
        MT.Type,
        Tariff,
        Reading,
        Estimated,
        ROUND(Reading, 0)                                                    AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Identifier, Type ORDER BY Timestamp) AS SeqNo,
		MR.Comment
	FROM MeterReading MR
	JOIN Meter  AS MT
    ON  MR.Meter    = MT.Identifier 
    AND MR.Timestamp >= MT.Installed
    AND (MT.Removed IS NULL OR MR.Timestamp < MT.Removed)) AS J2
	ON J1.SeqNo       = J2.SeqNo - 1
	AND J1.Type       = J2.Type
	AND J1.Identifier = J2.Identifier
LEFT JOIN Tariff  TR 
ON   J1.Timestamp >=  TR.Start 
AND (J1.Timestamp < TR.[End] OR TR.[End] IS NULL)
AND TR.Code = J1.Tariff
AND TR.Type = J1.Type

GO

DROP VIEW IF EXISTS CostedReading;
GO

CREATE VIEW CostedReading AS
SELECT
	*,    
    ROUND(UnitRate * Kwh / 100, 3)                           AS KwhCost,
    ROUND(Days * StandingCharge / 100, 3)                    AS StdCost,
    ROUND((UnitRate * Kwh + Days * StandingCharge) / 100, 3) AS TotalCost
FROM BoundedReading
GO