   
DROP VIEW IF EXISTS BoundedReadingOld;

CREATE VIEW BoundedReadingOld AS
SELECT
	J1.Timestamp                         AS Start,
    J1.Type,
    J1.Estimated                         AS StartEstimated,
    J1.Weekday,
    J2.Timestamp                         AS 'End',
    J2.Estimated                         AS EndEstimated,
    DATEDIFF(J2.Timestamp, J1.Timestamp) AS Days,
    J1.Reading                           AS StartReading,
    J2.Reading                           AS EndReading,
    J1.SeqNo,
    J2.Reading - J1.Reading              AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        UnitsToKwh(J2.TruncReading - J1.TruncReading, TR.CalorificValue)
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
        Type,
        Tariff,
        Reading,
        Estimated,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Type ORDER BY Timestamp) AS SeqNo,
        Comment
	FROM MeterReading) AS J1
JOIN (
	SELECT 
		Timestamp,
        Type,
        Tariff,
        Reading,
        Estimated,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Type ORDER BY Timestamp) AS SeqNo
	FROM MeterReading) AS J2
	ON J1.SeqNo = J2.SeqNo - 1
	AND J1.Type = J2.Type
LEFT JOIN Tariff  TR 
ON   J1.Timestamp >=  TR.Start 
AND (J1.Timestamp < TR.End OR TR.End IS NULL)
AND TR.Code = J1.Tariff
AND TR.Type = J1.Type;

DROP TABLE IF EXISTS MeterReadingOld;

CREATE TABLE MeterReadingOld (
	Timestamp DATETIME       NOT NULL,
    WeekDay   VARCHAR(3)     GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
	Type      VARCHAR(15)    NOT NULL,
	Tariff    VARCHAR(15)    NOT NULL DEFAULT 'SSEStd',
	Modified  DATETIME       NULL,
	Reading   DECIMAL(10, 2) NULL,
    Estimated CHAR(1)        NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Timestamp, Type)
);

DELIMITER //

CREATE TRIGGER InsMeterReadingOld BEFORE INSERT ON MeterReading
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdMeterReadingOld BEFORE UPDATE ON MeterReadingOld
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;


DROP VIEW IF EXISTS MergedSessionOld;

CREATE VIEW MergedSessionOld AS
SELECT
	CS.CarReg,
	CS.Mileage,
	Count(*)                                  AS Sessions,
	Min(CS.Start)                             AS Start,
	Max(CS.End)                               AS End,
	SUM(CS.EstDuration)                       AS EstDuration,
	SUM(CS.Duration)                          AS Duration,
	MAX(CS.EndPerCent)                        AS EndPercent,
	MAX(CS.EndPerCent) - MIN(CS.StartPerCent) AS SessionPercent,
	SUM(CS.SessionMiles)                      AS SessionMiles,
	SUM(CS.Charge)                            AS Charge,
	SUM(CS.ICharge)                           AS InputCharge,
	SUM(CS.CCharge)                           AS CalculatedCharge,
	SUM(CS.Cost)                              AS Cost,
	SUM(CS.ICost)                             AS InputCost,
	SUM(CS.CCost)                             AS CalculatedCost,
	SUM(J2.Mileage    - CS.Mileage)           AS CarMiles,
	SUM(CS.EndPerCent - J2.StartPercent)      AS CarPercent,
	MAX(CS.Charger)                           AS Charger,
	MAX(CS.Unit)                              AS Unit,
	MAX(CS.UnitRate)                          AS UnitRate,
	MAX(CS.Capacity)                          AS Capacity,
	MAX(CS.MilesPerLitre)                     AS MilesPerLitre,
	MAX(CS.DefaultTariff)                     AS DefaultTariff,
	MAX(CS.DefaultUnitRate)                   AS DefaultUnitRate
	FROM (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, CH.Start) Num, 
	    CarReg,
		CH.Start,
		CH.End,
		EstDuration,
		CAST(TIMESTAMPDIFF(SECOND, CH.Start, CH.End)/3600.0 AS DECIMAL(9, 5))                 AS Duration,
		Mileage,
		StartPerCent,
		EndPerCent,
		EndMiles   - StartMiles                                                               AS SessionMiles,
		EndPercent - StartPercent                                                             AS SessionPercent,
		Capacity,
		MilesPerLitre,
		COALESCE(Charge, CAST((EndPercent - StartPercent) / 100 * Capacity AS DECIMAL(8, 2))) AS Charge,
		Charge                                                                                AS ICharge,
		CAST((EndPercent - StartPercent) / 100 * Capacity AS DECIMAL(8, 2))                   AS CCharge,
		COALESCE(Cost, CAST((TF.UnitRate * Charge / 100) AS DECIMAL(8, 2)))                   AS Cost,
		Cost                                                                                  AS ICost,
		CAST(TF.UnitRate * Charge / 100 AS DECIMAL(8, 2))                                     AS CCost,
		Charger,
		Unit,
		COALESCE(TF.UnitRate, 0)                                                              AS UnitRate,
		DefaultTariff,
		COALESCE(TD.UnitRate, 0)                                                              AS DefaultUnitRate
	FROM Expenditure.ChargeSession CH
	LEFT JOIN Expenditure.ChargerLocation CL
	ON  CH.Charger = CL.Name
	LEFT JOIN Expenditure.Tariff TF
	ON        CL.Tariff = TF.Code 
	AND       TF.Type   = 'Electric' 
	AND       CH.Start  > TF.Start 
	AND      (CH.End    < TF.End OR TF.End IS NULL)
	JOIN Expenditure.Car
	ON Car.Registration = CarReg
	LEFT JOIN Expenditure.Tariff TD
	ON        Car.DefaultTariff = TD.Code 
	AND       TD.Type    = 'Electric' 
	AND       CH.Start  >= TD.Start 
	AND      (CH.Start  < TD.End OR TD.End IS NULL)) CS
LEFT OUTER JOIN (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, Start) Num,
		CarReg,
		StartPercent,
		Mileage
    FROM Expenditure.ChargeSession) J2
ON  J2.Num    = CS.Num + 1
AND J2.CarReg = CS.CarReg
GROUP BY CS.CarReg, CS.Mileage;

DROP VIEW IF EXISTS SessionUsageOld;

CREATE VIEW SessionUsageOld AS
SELECT 
	CarReg,
	MS.Start, 
	MS.End,
    Duration,
	Mileage,
	Charger,
	Unit,
	Capacity,
	MilesPerLitre,
	WF.PumpPrice,
	CarMiles,
	CarPercent,
	CAST(CarPercent * Capacity / 100 AS DECIMAL(8, 2))                    AS CarCharge,
	CAST(CarPercent * Capacity * MS.UnitRate / 10000 AS DECIMAL(8, 2))    AS CarElectric,
	CAST(CarMiles /MilesPerLitre * WF.PumpPrice / 100 AS DECIMAL(8, 2))   AS CarPetrol,
    EndPercent,
	SessionPercent,
	MS.UnitRate,
	Charge,
    Charge * 100 / SessionPercent                                         AS FullCharge,
	InputCharge,
	CalculatedCharge,
	Cost,
	InputCost,
	CalculatedCost,
	TR.UnitRate                                                           AS DefaultRate,
	CAST(Charge * TR.UnitRate / 100 AS DECIMAL(8, 2))                     AS DefaultSessionCost,
	Cost - CAST(Charge * TR.UnitRate / 100 AS DECIMAL(8, 2))              AS DefaultCostDiff
FROM      Expenditure.MergedSessionOld MS
LEFT JOIN Expenditure.WeeklyFuel WF
ON   MS.Start >  WF.Start 
AND (MS.Start <= WF.End OR WF.End IS NULL)
LEFT JOIN Expenditure.Tariff TR
ON   MS.Start >  TR.Start 
AND (MS.Start <= TR.End OR TR.End IS NULL)
AND TR.Code = DefaultTariff
AND TR.Type = 'Electric';


DROP VIEW IF EXISTS MergedSessionOld;

CREATE VIEW MergedSessionOld AS
SELECT
	CS.CarReg,
	CS.Mileage,
	Count(*)                                  AS Sessions,
	Min(CS.Start)                             AS Start,
	Max(CS.End)                               AS End,
	SUM(CS.EstDuration)                       AS EstDuration,
	SUM(CS.Duration)                          AS Duration,
	MAX(CS.EndPerCent)                        AS EndPercent,
	MAX(CS.EndPerCent) - MIN(CS.StartPerCent) AS SessionPercent,
	SUM(CS.SessionMiles)                      AS SessionMiles,
	SUM(CS.Charge)                            AS Charge,
	SUM(CS.ICharge)                           AS InputCharge,
	SUM(CS.CCharge)                           AS CalculatedCharge,
	SUM(CS.Cost)                              AS Cost,
	SUM(CS.ICost)                             AS InputCost,
	SUM(CS.CCost)                             AS CalculatedCost,
	SUM(J2.Mileage    - CS.Mileage)           AS CarMiles,
	SUM(CS.EndPerCent - J2.StartPercent)      AS CarPercent,
	MAX(CS.Charger)                           AS Charger,
	MAX(CS.Unit)                              AS Unit,
	MAX(CS.UnitRate)                          AS UnitRate,
	MAX(CS.Capacity)                          AS Capacity,
	MAX(CS.MilesPerLitre)                     AS MilesPerLitre,
	MAX(CS.DefaultTariff)                     AS DefaultTariff,
	MAX(CS.DefaultUnitRate)                   AS DefaultUnitRate
	FROM (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, CH.Start) Num, 
	    CarReg,
		CH.Start,
		CH.End,
		EstDuration,
		CAST(TIMESTAMPDIFF(SECOND, CH.Start, CH.End)/3600.0 AS DECIMAL(9, 5))                 AS Duration,
		Mileage,
		StartPerCent,
		EndPerCent,
		EndMiles   - StartMiles                                                               AS SessionMiles,
		EndPercent - StartPercent                                                             AS SessionPercent,
		Capacity,
		MilesPerLitre,
		COALESCE(Charge, CAST((EndPercent - StartPercent) / 100 * Capacity AS DECIMAL(8, 2))) AS Charge,
		Charge                                                                                AS ICharge,
		CAST((EndPercent - StartPercent) / 100 * Capacity AS DECIMAL(8, 2))                   AS CCharge,
		COALESCE(Cost, CAST((TF.UnitRate * Charge / 100) AS DECIMAL(8, 2)))                   AS Cost,
		Cost                                                                                  AS ICost,
		CAST(TF.UnitRate * Charge / 100 AS DECIMAL(8, 2))                                     AS CCost,
		Charger,
		Unit,
		COALESCE(TF.UnitRate, 0)                                                              AS UnitRate,
		DefaultTariff,
		COALESCE(TD.UnitRate, 0)                                                              AS DefaultUnitRate
	FROM Expenditure.ChargeSession CH
	LEFT JOIN Expenditure.ChargerLocation CL
	ON  CH.Charger = CL.Name
	LEFT JOIN Expenditure.Tariff TF
	ON        CL.Tariff = TF.Code 
	AND       TF.Type   = 'Electric' 
	AND       CH.Start  > TF.Start 
	AND      (CH.End    < TF.End OR TF.End IS NULL)
	JOIN Expenditure.Car
	ON Car.Registration = CarReg
	LEFT JOIN Expenditure.Tariff TD
	ON        Car.DefaultTariff = TD.Code 
	AND       TD.Type    = 'Electric' 
	AND       CH.Start  >= TD.Start 
	AND      (CH.Start  < TD.End OR TD.End IS NULL)) CS
LEFT OUTER JOIN (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, Start) Num,
		CarReg,
		StartPercent,
		Mileage
    FROM Expenditure.ChargeSession) J2
ON  J2.Num    = CS.Num + 1
AND J2.CarReg = CS.CarReg
GROUP BY CS.CarReg, CS.Mileage;

DROP VIEW IF EXISTS SessionUsageOld;

CREATE VIEW SessionUsageOld AS
SELECT 
	CarReg,
	MS.Start, 
	MS.End,
    Duration,
	Mileage,
	Charger,
	Unit,
	Capacity,
	MilesPerLitre,
	WF.PumpPrice,
	CarMiles,
	CarPercent,
	CAST(CarPercent * Capacity / 100 AS DECIMAL(8, 2))                    AS CarCharge,
	CAST(CarPercent * Capacity * MS.UnitRate / 10000 AS DECIMAL(8, 2))    AS CarElectric,
	CAST(CarMiles /MilesPerLitre * WF.PumpPrice / 100 AS DECIMAL(8, 2))   AS CarPetrol,
    EndPercent,
	SessionPercent,
	MS.UnitRate,
	Charge,
    Charge * 100 / SessionPercent                                         AS FullCharge,
	InputCharge,
	CalculatedCharge,
	Cost,
	InputCost,
	CalculatedCost,
	TR.UnitRate                                                           AS DefaultRate,
	CAST(Charge * TR.UnitRate / 100 AS DECIMAL(8, 2))                     AS DefaultSessionCost,
	Cost - CAST(Charge * TR.UnitRate / 100 AS DECIMAL(8, 2))              AS DefaultCostDiff
FROM      Expenditure.MergedSessionOld MS
LEFT JOIN Expenditure.WeeklyFuel WF
ON   MS.Start >  WF.Start 
AND (MS.Start <= WF.End OR WF.End IS NULL)
LEFT JOIN Expenditure.Tariff TR
ON   MS.Start >  TR.Start 
AND (MS.Start <= TR.End OR TR.End IS NULL)
AND TR.Code = DefaultTariff
AND TR.Type = 'Electric';

DROP VIEW IF EXISTS SessionMonthSummary;

CREATE VIEW SessionMonthSummary AS
    SELECT 
        YEAR(Start) AS Year,
        MONTH(Start) AS Month,
        COUNT(*) AS Sessions,
        SUM(SessionPercent) AS SessionPercent,
        CAST(AVG(PumpPrice) AS DECIMAL (8 , 1 )) AS Petrol,
        SUM(Charge) AS Charge,
        SUM(Cost) AS Cost,
        SUM(CarPercent) AS CarPercent,
        SUM(CarCharge) AS CarCharge,
        SUM(CarMiles) AS CarMiles,
        SUM(CarElectric) AS CarElectric,
        SUM(CarPetrol) AS CarPetrol,
        SUM(DefaultCostDiff) AS DefaultCostDiff
    FROM
        expenditure.sessionusageOld
    GROUP BY YEAR(Start) , MONTH(Start);

DROP VIEW IF EXISTS BoundedReadingOld;

CREATE VIEW BoundedReadingOld AS
SELECT
	J1.Timestamp                         AS Start,
    J1.Identifier                        AS Meter,
    J1.Type,
    J1.Estimated                         AS StartEstimated,
    J1.Weekday,
    J2.Timestamp                         AS 'End',
    J2.Estimated                         AS EndEstimated,
    DATEDIFF(J2.Timestamp, J1.Timestamp) AS Days,
    J1.Reading                           AS StartReading,
    COALESCE(J1.OffPeakKwhx, 0)           AS OffPeakKwhX,
    J2.Reading                           AS EndReading,
    J1.SeqNo,
    J2.Reading - J1.Reading              AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        UnitsToKwh(J2.TruncReading - J1.TruncReading, TR.CalorificValue)
      ELSE 
		J2.TruncReading - J1.TruncReading
      END AS Kwh,
    J1.Tariff,
    TR.UnitRate,
    TR.OffPeakRate,
    TR.StandingCharge,
    TR.CalorificValue,
    J1.Comment
FROM (
SELECT 
		Timestamp,
        Weekday,
        MT.Identifier,
        MT.Type,
        MRT.Tariff,
        Reading,
        OffPeakKwhx,
        Estimated,
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
        Estimated,
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

    
DROP VIEW IF EXISTS CostedReadingOld;

CREATE VIEW CostedReadingOld AS
SELECT
	*,    
    Kwh - OffPeakKwhx                                                    AS PeakKwh,
    ROUND(UnitRate * Kwh / 100, 2)                                      AS KwhCost,
    ROUND(Days * StandingCharge / 100, 2)                               AS StdCost,
    ROUND(UnitRate * (Kwh - OffPeakKwhx) / 100, 2)                       AS PeakKwhCost,
    COALESCE(ROUND(OffPeakRate * OffPeakKwhx / 100, 2), 0)               AS OffPeakKwhCost,    
--    ROUND((UnitRate * Kwh + Days * StandingCharge) / 100, 2) AS TotalCost,
    ROUND((UnitRate * (Kwh - OffPeakKwhx) + 
           COALESCE(OffPeakRate * OffPeakKwhx, 0) + 
           Days * StandingCharge) / 100, 2)                             AS TotalCost,
    COALESCE(ROUND((UnitRate -OffPeakRate) * OffPeakKwhx / 100, 2), 0)   AS OffPeakSaving
FROM BoundedReadingOld;
