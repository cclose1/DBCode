DROP VIEW NutritionItem
GO
CREATE VIEW NutritionItem
AS
SELECT 
	Item,
	Type,
	Source,
	Start,
	[End],
	Modified,
	Calories,
	4 * (ISNULL(Carbohydrate, 0) + ISNULL(Protein, 0)) + 9 * ISNULL(Fat, 0) AS CalculateCalories,
	Protein,
	Fat,
	Saturated,
	Carbohydrate,
	Sugar,
	Fibre,
	Cholesterol,
	Salt,
	NULL AS Units,
	DefaultSize,
	ABV,
	ISNULL(Simple, 'N') AS Simple,
	PackSize
FROM NutritionDetail
UNION
SELECT
	NC.Item,
	MIN(NC.Type)                  AS Type,
	NC.Source,
	NC.Start,
	MIN(NC.[End])                 AS [End],
	MIN(NC.Modified)              AS Modified,
	4 * (ISNULL(SUM(Quantity * Carbohydrate), 0) + ISNULL(SUM(Quantity * Protein), 0)) + 9 * ISNULL(SUM(Quantity * Fat), 0) + 56 * ISNULL(SUM(Quantity * NR.ABV / 1000), 0) AS CalculateCalories,
	SUM(Quantity * Calories)      AS Calories,
	SUM(Quantity * Protein)       AS Protein,
	SUM(Quantity * Fat)           AS Fat,
	SUM(Quantity * Saturated)     AS Saturated,
	SUM(Quantity * Carbohydrate)  AS Carbohydrate,
	SUM(Quantity * Sugar)         AS Sugar,
	SUM(Quantity * Fibre)         AS Fibre,
	SUM(Quantity * Cholesterol)   AS Cholesterol,
	SUM(Quantity * Salt)          AS Salt,
	SUM(Quantity * NR.ABV / 1000) AS Units,
	1                             AS DefaultSize,
	NULL                          AS ABV,
	'C'                           AS Simple,
	NULL                          AS PackSize
FROM NutritionComposite NC
JOIN NutritionRecord    NR
ON NC.Record = NR.Timestamp
JOIN NutritionDetail ND
ON  NR.Timestamp BETWEEN ND.Start AND ND.[End]
AND NR.Item   = ND.Item
AND NR.Source = ND.Source
GROUP BY NC.Start, NC.Item, NC.Source
GO

DROP VIEW NutritionEventSummary
GO
CREATE VIEW NutritionEventSummary
AS
SELECT
	EV.Timestamp,
	CAST(EV.Timestamp AS DATE) AS Date,
	Year,
	Month,
	Day,
	Week,
	Weekday,
    CAST(DATEADD(D, -DATEPART(w, EV.Timestamp), EV.Timestamp) AS DATE) AS WeekStart,
	'New'   AS Type,
	Description,
	Comment,
	Items,
	Quantity,
	CAST(Calories     AS INT)            AS Calories,
	CAST(Protein      AS DECIMAL(12, 1)) AS Protein,
	CAST(Fat          AS DECIMAL(12, 1)) AS Fat,
	CAST(Saturated    AS DECIMAL(12, 1)) AS Saturated,
	CAST(Carbohydrate AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(Sugar        AS DECIMAL(12, 1)) AS Sugar,
	CAST(Fibre        AS DECIMAL(12, 1)) AS Fibre,
	CAST(Cholesterol  AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(Salt         AS DECIMAL(12, 1)) AS Salt,
	CAST(Units        AS DECIMAL(12, 1)) AS Units
FROM NutritionEvent     EV
LEFT JOIN (
	SELECT
		Timestamp,
		COUNT(*) AS Items,
		SUM(Quantity)                                     AS Quantity,
		SUM(Quantity * Calories)                          AS Calories,
		SUM(Quantity * Protein)                           AS Protein,
		SUM(Quantity * Fat)                               AS Fat,
		SUM(Quantity * Saturated)                         AS Saturated,
		SUM(Quantity * Carbohydrate)                      AS Carbohydrate,
		SUM(Quantity * Sugar)                             AS Sugar,
		SUM(Quantity * Fibre)                             AS Fibre,
		SUM(Quantity * Cholesterol)                       AS Cholesterol,
		SUM(Quantity * Salt)                              AS Salt,
		SUM(Quantity * COALESCE(NR.ABV / 1000, NI.Units)) AS Units
	FROM NutritionRecord NR
	JOIN NutritionItem   NI
	ON  NR.Item   = NI.Item
	AND NR.Source = NI.Source
	AND NR.Timestamp BETWEEN NI.Start AND NI.[End]
	AND (NR.IsComposite = 'Y' AND NI.Simple = 'C' OR ISNULL(NR.IsComposite, 'N') = 'N' AND NI.Simple <> 'C')
	GROUP BY Timestamp) J1
ON J1.Timestamp = EV.Timestamp
UNION
SELECT
	Timestamp,
	CAST(Timestamp AS DATE) AS Date,
	Year,
	Month,
	Day,
	Week,
	Weekday,
    CAST(DATEADD(D, -DATEPART(w, timestamp), Timestamp) AS DATE) AS WeekStart,
	'Old'   AS Type,
	Description,
	NULL AS Comment,
	NULL AS Items,
	NULL AS Quantity,
	CAST(Calories     AS INT)            AS Calories,
	CAST(Fat          AS DECIMAL(12, 1)) AS Protein,
	CAST(Fat          AS DECIMAL(12, 1)) AS Fat,
	CAST(Saturated    AS DECIMAL(12, 1)) AS Saturated,
	CAST(Carbohydrate AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(Sugar        AS DECIMAL(12, 1)) AS Sugar,
	CAST(Fibre        AS DECIMAL(12, 1)) AS Fibre,
	CAST(Cholesterol  AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(Salt         AS DECIMAL(12, 1)) AS Salt,
	CAST(Units        AS DECIMAL(12, 1)) AS Units
FROM NutritionHistorical
GO
DROP VIEW NutritionEventsDaily
GO
CREATE VIEW NutritionEventsDaily
AS
SELECT
	J1.*,
	WT.Kilos
FROM (
	SELECT
		Year,
		Month,
		Day,
		CAST(MIN(Timestamp) AS DATE) AS Date,
		MIN(WeekDay)                 AS Weekday,
		SUM(Calories)                AS Calories,
		SUM(Protein)                 AS Protein,
		SUM(Fat)                     AS Fat,
		SUM(Saturated)               AS Saturated,
		SUM(Carbohydrate)            AS Carbohydrate,
		SUM(Sugar)                   AS Sugar,
		SUM(Fibre)                   AS Fibre,
		SUM(Cholesterol)             AS Cholesterol,
		SUM(Salt)                    AS Salt,
		SUM(Units)                   AS Units
	FROM NutritionEventSummary
	GROUP BY Year, Month, Day) J1
LEFT JOIN Weight               WT
ON J1.Date = WT.Date
GO
DROP VIEW NutritionEventsWeekly
GO
CREATE VIEW NutritionEventsWeekly
AS
SELECT 
	J1.*,
	WT.Kilos,
	CAST(Calories     / Days AS INT)            AS DailyCalories,
	CAST(Protein      / Days AS NUMERIC(10, 1)) AS DailyProtein,
	CAST(Fat          / Days AS NUMERIC(10, 1)) AS DailyFat,
	CAST(Saturated    / Days AS NUMERIC(10, 1)) AS DailySaturated,
	CAST(Carbohydrate / Days AS NUMERIC(10, 1)) AS DailyCarbohydrate,
	CAST(Sugar        / Days AS NUMERIC(10, 1)) AS DailySugar,
	CAST(Fibre        / Days AS NUMERIC(10, 1)) AS DailyFibre,
	CAST(Cholesterol  / Days AS NUMERIC(10, 1)) AS DailyCholesterol,
	CAST(Salt         / Days AS NUMERIC(10, 1)) AS DailySalt,
	CAST(Units        / Days AS NUMERIC(10, 1)) AS DailyUnits
FROM (
	SELECT
		Year,
		Week,
		CAST(MIN(Timestamp) AS DATE) AS Date,
		DATEDIFF(D, MIN(Timestamp), MAX(Timestamp)) + 1 AS Days,
		SUM(Calories)                                   AS Calories,
		SUM(Protein)                                    AS Protein,
		SUM(Fat)                                        AS Fat,
		SUM(Saturated)                                  AS Saturated,
		SUM(Carbohydrate)                               AS Carbohydrate,
		SUM(Sugar)                                      AS Sugar,
		SUM(Fibre)                                      AS Fibre,	
		SUM(Cholesterol)                                AS Cholesterol,
		SUM(Salt)                                       AS Salt,
		SUM(Units)                                      AS Units
	FROM NutritionEventSummary
	GROUP BY Year, Week) J1
LEFT JOIN Weight WT
ON J1.Date = WT.Date
GO
DROP VIEW NutritionEventsWeeklyNew
GO
CREATE VIEW NutritionEventsWeeklyNew
AS
SELECT 
	J1.*,
	WT.Kilos,
	CAST(Calories     / Days AS INT)            AS DailyCalories,
	CAST(Protein      / Days AS NUMERIC(10, 1)) AS DailyProtein,
	CAST(Fat          / Days AS NUMERIC(10, 1)) AS DailyFat,
	CAST(Saturated    / Days AS NUMERIC(10, 1)) AS DailySaturated,
	CAST(Carbohydrate / Days AS NUMERIC(10, 1)) AS DailyCarbohydrate,
	CAST(Sugar        / Days AS NUMERIC(10, 1)) AS DailySugar,
	CAST(Fibre        / Days AS NUMERIC(10, 1)) AS DailyFibre,
	CAST(Cholesterol  / Days AS NUMERIC(10, 1)) AS DailyCholesterol,
	CAST(Salt         / Days AS NUMERIC(10, 1)) AS DailySalt,
	CAST(Units        / Days AS NUMERIC(10, 1)) AS DailyUnits
FROM (
	SELECT
		WeekStart,
		CAST(MIN(Timestamp) AS DATE) AS Date,
		DATEDIFF(D, MIN(Timestamp), MAX(Timestamp)) + 1 AS Days,
		SUM(Calories)                                   AS Calories,
		SUM(Protein)                                    AS Protein,
		SUM(Fat)                                        AS Fat,
		SUM(Saturated)                                  AS Saturated,
		SUM(Carbohydrate)                               AS Carbohydrate,
		SUM(Sugar)                                      AS Sugar,
		SUM(Fibre)                                      AS Fibre,	
		SUM(Cholesterol)                                AS Cholesterol,
		SUM(Salt)                                       AS Salt,
		SUM(Units)                                      AS Units
	FROM NutritionEventSummary
	GROUP BY WeekStart) J1
LEFT JOIN Weight WT
ON J1.Date = WT.Date
GO
DROP VIEW NutritionRecordFull
GO
CREATE VIEW NutritionRecordFull
AS
SELECT
	NE.Timestamp,
	NE.Year,
	NE.Month,
	NE.Day,
	NE.Week,
	NE.Weekday,
	NE.Description,
	NI.Item,
	NI.Source,
	NI.Type,
	NR.Quantity,
	NR.ABV,	
	NR.IsComposite,
	NI.Simple,
	NI.Calories                                           AS ICalories,
	NI.Protein                                            AS IProtein,
	NI.Fat                                                AS IFat,
	NI.Saturated                                          AS ISaturated,
	NI.Carbohydrate                                       AS ICarbohydrate,
	NI.Sugar                                              AS ISugar,
	NI.Fibre                                              AS IFibre,
	NI.Cholesterol                                        AS ICholesterol,
	NI.Salt                                               AS ISalt,
	NI.DefaultSize,
	NI.ABV                                                AS DefaultABV,
	CAST(NR.Quantity * NI.Calories     AS DECIMAL(12, 1)) AS Calories,
	CAST(NR.Quantity * NI.Protein      AS DECIMAL(12, 1)) AS Protein,
	CAST(NR.Quantity * NI.Fat          AS DECIMAL(12, 1)) AS Fat,
	CAST(NR.Quantity * NI.Saturated    AS DECIMAL(12, 1)) AS Saturated,
	CAST(NR.Quantity * NI.Carbohydrate AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(NR.Quantity * NI.Sugar        AS DECIMAL(12, 1)) AS Sugar,
	CAST(NR.Quantity * NI.Fibre        AS DECIMAL(12, 1)) AS Fibre,
	CAST(NR.Quantity * NI.Cholesterol  AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(NR.Quantity * NI.Salt         AS DECIMAL(12, 1)) AS Salt,
	CAST(NR.Quantity * NI.ABV / 1000   AS DECIMAL(12, 1)) AS Units
FROM NutritionEvent  NE
JOIN NutritionRecord NR
ON NE.Timestamp = NR.Timestamp
JOIN NutritionItem NI
ON  NR.Item      = NI.Item
AND NR.Source    = NI.Source
AND NR.Timestamp BETWEEN NI.Start AND NI.[End]
AND (NR.IsComposite = 'Y' AND NI.Simple = 'C' OR ISNULL(NR.IsComposite, 'N') = 'N' AND NI.Simple <> 'C')
GO
DROP VIEW CalculatedDetails
GO
CREATE VIEW CalculatedDetails
AS
SELECT
	D.*,
	CAST(100 * D.CalculatedCalories / D.Calories AS INT) AS Diff
FROM (
	SELECT 
		Item,
		Type,
		Source,
		Start,
		Calories,
		4 * (ISNULL(Protein, 0) + ISNULL(Carbohydrate, 0)) + 9 * ISNULL(Fat, 0) + 56 * ISNULL(ABV, 0) / 1000 AS CalculatedCalories,
		Protein,
		Fat,
		Saturated,
		Carbohydrate,
		Sugar,
		Fibre,
		Salt,
		ABV,
		56 * ABV / 1000 AS AlcoholCalaries,
		Simple
	FROM BloodPressure.dbo.NutritionDetail) AS D
GO
DROP VIEW NutritionEventSummaryNew
GO

CREATE VIEW NutritionEventSummaryNew
AS
SELECT
	EV.Timestamp,
	CAST(EV.Timestamp AS DATE)                           AS Date,
	MIN(Year)                                            AS Year,
	MIN(Month)                                           AS Month,
	MIN(Day)                                             AS Day,
	MIN(Week)                                            AS Week,
	MIN(Weekday)                                         AS Weekday,
	'New'                                                AS Type,
	MIN(Description)                                     AS Description,
	MIN(Comment)                                         AS Comment,
	COUNT(*)                                             AS Items,
	SUM(Quantity)                                        AS Quantity,
	CAST(SUM(Quantity * Calories)     AS INT)            AS Calories,
	CAST(SUM(Quantity * Protein)      AS DECIMAL(12, 1)) AS Protein,
	CAST(SUM(Quantity * Fat)          AS DECIMAL(12, 1)) AS Fat,
	CAST(SUM(Quantity * Saturated)    AS DECIMAL(12, 1)) AS Saturated,
	CAST(SUM(Quantity * Carbohydrate) AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(SUM(Quantity * Sugar)        AS DECIMAL(12, 1)) AS Sugar,
	CAST(SUM(Quantity * Fibre)        AS DECIMAL(12, 1)) AS Fibre,
	CAST(SUM(Quantity * Cholesterol)  AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(SUM(Quantity * Salt)         AS DECIMAL(12, 1)) AS Salt,
	CAST(SUM(Quantity * NR.ABV / 1000)        AS DECIMAL(12, 1)) AS Units
FROM NutritionEvent     EV
LEFT JOIN NutritionRecord NR
ON EV.Timestamp = NR.Timestamp
LEFT JOIN NutritionItem  NI
ON  NR.Item   = NI.Item
AND NR.Source = NI.Source
AND NR.Timestamp BETWEEN NI.Start AND NI.[End]
AND (NR.IsComposite = 'Y' AND NI.Simple = 'C' OR ISNULL(NR.IsComposite, 'N') = 'N' AND NI.Simple <> 'C')
GROUP BY EV.Timestamp
UNION
SELECT
	Timestamp,
	CAST(Timestamp AS DATE) AS Date,
	Year,
	Month,
	Day,
	Week,
	Weekday,
	'Old'   AS Type,
	Description,
	NULL AS Comment,
	NULL AS Items,
	NULL AS Quantity,
	CAST(Calories     AS INT)            AS Calories,
	CAST(Fat          AS DECIMAL(12, 1)) AS Protein,
	CAST(Fat          AS DECIMAL(12, 1)) AS Fat,
	CAST(Saturated    AS DECIMAL(12, 1)) AS Saturated,
	CAST(Carbohydrate AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(Sugar        AS DECIMAL(12, 1)) AS Sugar,
	CAST(Fibre        AS DECIMAL(12, 1)) AS Fibre,
	CAST(Cholesterol  AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(Salt         AS DECIMAL(12, 1)) AS Salt,
	CAST(Units        AS DECIMAL(12, 1)) AS Units
FROM NutritionHistorical

GO