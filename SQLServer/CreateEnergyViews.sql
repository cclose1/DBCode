USE Expenditure
GO

DROP VIEW WeeklyFuel
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

DROP VIEW SessionUsedChargeX
GO

CREATE VIEW SessionUsedChargeX AS
SELECT
	CarReg,
	Mileage,
	Count(*)                            AS Sessions,
	Min(StartPercent)                   AS StartPercent,
	Max(EndPercent)                     AS EndPercent,
	Max(EndPercent) - Min(StartPercent) AS UsedPercent 
FROM Expenditure.dbo.ChargeSession
GROUP BY CarReg, Mileage
GO

DROP VIEW Chargers
GO

CREATE VIEW Chargers AS
SELECT
	CL.*,
	CU.Name  AS Unit,
	CU.Active
FROM Expenditure.dbo.ChargerLocation CL
LEFT JOIN Expenditure.dbo.ChargerUnit CU
ON CU.Location = CL.Name
GO

DROP VIEW MergedSession
GO

CREATE VIEW MergedSession AS
SELECT
	CS.CarReg,
	CS.Mileage,
	Count(*)                                  AS Sessions,
	Min(CS.Start)                             AS Start,
	Max(CS.[End])                             AS [End],
	SUM(CS.EstDuration)                       AS EstDuration,
	SUM(CS.Duration)                          AS Duration,
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
		CH.[End],
		EstDuration,
		CAST(DATEDIFF(ss, CH.Start, CH.[End])/3600.0 AS DECIMAL(9, 5))                        AS Duration,
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
		ISNULL(TF.UnitRate, 0)                                                                AS UnitRate,
		DefaultTariff,
		ISNULL(TD.UnitRate, 0)                                                                AS DefaultUnitRate
	FROM Expenditure.dbo.ChargeSession CH
	LEFT JOIN Expenditure.dbo.ChargerLocation CL
	ON  CH.Charger = CL.Name
	LEFT JOIN Expenditure.dbo.Tariff TF
	ON        CL.Tariff = TF.Name 
	AND       TF.Type   = 'Electric' 
	AND       CH.Start  > TF.Start 
	AND      (CH.[End]  < TF.[End] OR TF.[End] IS NULL)
	JOIN Expenditure.dbo.Car
	ON Car.Registration = CarReg
	LEFT JOIN Expenditure.dbo.Tariff TD
	ON        Car.DefaultTariff = TD.Name 
	AND       TD.Type   = 'Electric' 
	AND       CH.Start  > TD.Start 
	AND      (CH.[End]  < TD.[End] OR TD.[End] IS NULL)) CS
LEFT OUTER JOIN (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY CarReg, Start) Num,
		CarReg,
		StartPercent,
		Mileage
    FROM Expenditure.dbo.ChargeSession) J2
ON  J2.Num    = CS.Num + 1
AND J2.CarReg = CS.CarReg
GROUP BY CS.CarReg, CS.Mileage
GO

DROP VIEW SessionUsage
GO

CREATE VIEW SessionUsage AS
SELECT 
	CarReg,
	MS.Start, 
	MS.[End],
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
	SessionPercent,
	MS.UnitRate,
	Charge,
	InputCharge,
	CalculatedCharge,
	Cost,
	InputCost,
	CalculatedCost,
	TR.UnitRate                                                            AS DefaultRate,
	CAST(Charge * TR.UnitRate / 100 AS DECIMAL(8, 2))                      AS DefaultSessionCost,
	Cost - CAST(Charge * TR.UnitRate / 100 AS DECIMAL(8, 2))               AS DefaultCostDiff
FROM      Expenditure.dbo.MergedSession MS
LEFT JOIN Expenditure.dbo.WeeklyFuel WF
ON   MS.Start > WF.Start 
AND (MS.[End] < WF.[End] OR WF.[End] IS NULL)
LEFT JOIN Expenditure.dbo.Tariff TR
ON   MS.Start > TR.Start 
AND (MS.[End] < TR.[End] OR TR.[End] IS NULL)
AND TR.Name = DefaultTariff
AND TR.Type = 'Electric'
GO
