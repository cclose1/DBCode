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
	CL.*,
	CU.Name  AS Unit,
	CU.Active
FROM Expenditure.ChargerLocation CL
LEFT JOIN Expenditure.ChargerUnit CU
ON CU.Location = CL.Name;

DROP VIEW IF EXISTS MergedSession;

CREATE VIEW MergedSession AS
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

DROP VIEW IF EXISTS SessionUsage;

CREATE VIEW SessionUsage AS
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
FROM      Expenditure.MergedSession MS
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
        expenditure.sessionusage
    GROUP BY YEAR(Start) , MONTH(Start);
    
DROP VIEW IF EXISTS SequencedMeterReading;

CREATE VIEW SequencedMeterReading AS
SELECT 
	Timestamp,
    MR.Type,
    ROW_NUMBER() OVER (PARTITION BY Type ORDER BY Timestamp) AS SeqNo,
    Tariff,
    Reading,
    UnitRate,
    StandingCharge,
    COALESCE(CalorificValue, '') AS CalorificValue
FROM MeterReading MR
LEFT JOIN Tariff  TR 
ON   MR.Timestamp >=  TR.Start 
AND (MR.Timestamp < TR.End OR TR.End IS NULL)
AND TR.Code = MR.Tariff
AND TR.Type = MR.Type;

DROP VIEW IF EXISTS BoundedReading;

CREATE VIEW BoundedReading AS
SELECT
	J1.Timestamp                         AS Start,
    J1.Weekday,
    J2.Timestamp                         AS 'End',
    DATEDIFF(J2.Timestamp, J1.Timestamp) AS Days,
    J1.SeqNo,
    J1.Type,
    J1.Tariff,
    J1.Reading,
    J2.Reading                           AS NextReading,
    J2.Reading - J1.Reading              AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        UnitsToKwh(J2.Reading - J1.Reading, TR.CalorificValue)
      ELSE 
		J2.Reading - J1.Reading
      END AS Kwh,
    TR.UnitRate,
    TR.StandingCharge,
    TR.CalorificValue,
    J1.Comment
FROM (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY Type ORDER BY Timestamp) AS SeqNo
	FROM MeterReading) AS J1
JOIN (
	SELECT 
		*,
		ROW_NUMBER() OVER (PARTITION BY Type ORDER BY Timestamp) AS SeqNo
	FROM MeterReading) AS J2
	ON J1.SeqNo = J2.SeqNo - 1
	AND J1.Type = J2.Type
LEFT JOIN Tariff  TR 
ON   J1.Timestamp >=  TR.Start 
AND (J1.Timestamp < TR.End OR TR.End IS NULL)
AND TR.Code = J1.Tariff
AND TR.Type = J1.Type;

DROP VIEW IF EXISTS CostedReading;

CREATE VIEW CostedReading AS
SELECT
	*,    
    ROUND(UnitRate * Kwh / 100, 3)                           AS KwhCost,
    ROUND(Days * StandingCharge / 100, 3)                    AS StdCost,
    ROUND((UnitRate * Kwh + Days * StandingCharge) / 100, 3) AS TotalCost
FROM BoundedReading;
