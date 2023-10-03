
DROP VIEW IF EXISTS NutritionItem;

CREATE VIEW NutritionItem
AS
SELECT 
	Item,
	Type,
	Source,
	Start,
	End,
	Modified,
	Calories,
	CalculateCalories(Fat, Carbohydrate, Protein, Null)  AS CalculateCalories,
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
	COALESCE(Simple, 'N') AS Simple,
    IsVolume,
	PackSize
FROM NutritionDetail
UNION
SELECT
	NC.Item,
	MIN(NC.Type)                                        AS Type,
	NC.Source,
	NC.Start,
	MIN(NC.End)                                         AS End,
	MIN(NC.Modified)                                    AS Modified,
	CAST(SUM(Quantity * Calories)     AS DECIMAL(6, 2)) AS Calories,
	CalculateCalories(SUM(Quantity * Fat), SUM(Quantity * Fat), SUM(Quantity * Protein), SUM(Quantity * NR.ABV / 1000)) AS CalculateCalories,
	CAST(SUM(Quantity * Protein)      AS DECIMAL(6, 2)) AS Protein,
	CAST(SUM(Quantity * Fat)          AS DECIMAL(6, 2)) AS Fat,
	CAST(SUM(Quantity * Saturated)    AS DECIMAL(6, 2)) AS Saturated,
	CAST(SUM(Quantity * Carbohydrate) AS DECIMAL(6, 2)) AS Carbohydrate,
	CAST(SUM(Quantity * Sugar)        AS DECIMAL(6, 2)) AS Sugar,
	CAST(SUM(Quantity * Fibre)        AS DECIMAL(6, 2)) AS Fibre,
	CAST(SUM(Quantity * Cholesterol)  AS DECIMAL(5, 2)) AS Cholesterol,
	CAST(SUM(Quantity * Salt)         AS DECIMAL(6, 3)) AS Salt,
	SUM(Quantity * NR.ABV / 1000)                       AS Units,
	1                                                   AS DefaultSize,
	NULL                                                AS ABV,
	'C'                                                 AS Simple,
    NULL                                                AS IsVolume,
	NULL                                                AS PackSize
FROM NutritionComposite NC
JOIN NutritionRecord    NR
ON NC.Record = NR.Timestamp
JOIN NutritionDetail ND
ON  NR.Timestamp BETWEEN ND.Start AND ND.End
AND NR.Item   = ND.Item
AND NR.Source = ND.Source
GROUP BY NC.Start, NC.Item, NC.Source;

DROP VIEW IF EXISTS NutritionEventSummary;

CREATE VIEW NutritionEventSummary
AS
SELECT
	EV.Timestamp,
	CAST(EV.Timestamp AS Date)                           AS Date,
	Year(EV.Timestamp)                                   AS Year,
	Month(EV.Timestamp)                                  AS Month,
	Day(EV.Timestamp)                                    AS Day,
	Week(EV.Timestamp) + 1                               AS Week,
	SubStr(DayName(EV.Timestamp), 1, 3)                  AS Weekday,
	WeekStart(EV.Timestamp)                              AS WeekStart,
	'New'                                                AS Type,
	Min(Description)                                     AS Description,
	Min(Comment)                                         AS Comment,
	Count(*)                                             AS Items,
	SUM(Quantity)                                        AS Quantity,
	Min(WT.Kilos)                                        AS Kilos,
	CAST(SUM(Quantity * Calories)      AS DECIMAL(4))    AS Calories,
	CAST(SUM(Quantity * Protein)       AS DECIMAL(5, 1)) AS Protein,
	CAST(SUM(Quantity * Fat)           AS DECIMAL(5, 1)) AS Fat,
	CAST(SUM(Quantity * Saturated)     AS DECIMAL(5, 1)) AS Saturated,
	CAST(SUM(Quantity * Carbohydrate)  AS DECIMAL(5, 1)) AS Carbohydrate,
	CAST(SUM(Quantity * Sugar)         AS DECIMAL(5, 1)) AS Sugar,
	CAST(SUM(Quantity * Fibre)         AS DECIMAL(5, 1)) AS Fibre,
	CAST(SUM(Quantity * Cholesterol)   AS DECIMAL(5, 1)) AS Cholesterol,
	CAST(SUM(Quantity * Salt)          AS DECIMAL(5, 1)) AS Salt,
	CAST(SUM(Quantity * NR.ABV / 1000) AS DECIMAL(5, 1)) AS Units
FROM NutritionEvent  EV
LEFT JOIN Weight     WT
ON WT.Date = CAST(EV.Timestamp AS DATE)
LEFT JOIN NutritionRecord NR
ON EV.Timestamp = NR.Timestamp
LEFT JOIN NutritionItem  NI
ON  NR.Item   = NI.Item
AND NR.Source = NI.Source
AND NR.Timestamp BETWEEN NI.Start AND NI.End
AND (NR.IsComposite = 'Y' AND NI.Simple = 'C' OR COALESCE(NR.IsComposite, 'N') = 'N' AND NI.Simple <> 'C')
GROUP BY EV.Timestamp
UNION
SELECT
	Timestamp,
	CAST(Timestamp AS DATE)              AS Date,
	Year(Timestamp)                      AS Year,
	Month(Timestamp)                     AS Month,
	Day(Timestamp)                       AS Day,
	Week(Timestamp) + 1                  AS Week,
	SubStr(DayName(Timestamp), 1, 3)     AS Weekday,
	WeekStart(Timestamp)                 AS WeekStart,
	'Old'                                AS Type,
	Description,
	NULL                                 AS Comment,
	NULL                                 AS Items,
	NULL                                 AS Quantity,
	WT.Kilos,
	CAST(Calories     AS DECIMAL(4))    AS Calories,
	CAST(Fat          AS DECIMAL(5, 1)) AS Protein,
	CAST(Fat          AS DECIMAL(5, 1)) AS Fat,
	CAST(Saturated    AS DECIMAL(5, 1)) AS Saturated,
	CAST(Carbohydrate AS DECIMAL(5, 1)) AS Carbohydrate,
	CAST(Sugar        AS DECIMAL(5, 1)) AS Sugar,
	CAST(Fibre        AS DECIMAL(5, 1)) AS Fibre,
	CAST(Cholesterol  AS DECIMAL(5, 1)) AS Cholesterol,
	CAST(Salt         AS DECIMAL(5, 1)) AS Salt,
	CAST(Units        AS DECIMAL(5, 1)) AS Units
FROM NutritionHistorical NH
LEFT JOIN Weight         WT
ON WT.Date = CAST(NH.Timestamp AS DATE);

DROP VIEW IF EXISTS NutritionEventsDaily;

CREATE VIEW NutritionEventsDaily
AS
SELECT
	Year,
	Month,
	Day,
	MIN(WeekStart)               AS WeekStart,
	MIN(EN.Date)                 AS Date,
	MIN(WeekDay)                 AS Weekday,
	MIN(WT.Kilos)                AS Kilos,
	BMI(MIN(WT.Kilos))           AS BMI,
	SUM(Calories)                AS Calories,
	SUM(Protein)                 AS Protein,
	SUM(Fat)                     AS Fat,
	SUM(Saturated)               AS Saturated,
	SUM(Carbohydrate)            AS Carbohydrate,
	SUM(Sugar)                   AS Sugar,
	SUM(Fibre)                   AS Fibre,
	SUM(Cholesterol)             AS Cholesterol,
	SUM(Salt)                    AS Salt,
	SUM(Units)                   AS Units,
	CalculateCalories(SUM(Fat), SUM(Carbohydrate), SUM(Protein), SUM(Units)) AS CalculatedCalories
FROM NutritionEventSummary     EN
LEFT JOIN Weight               WT
ON EN.Date = WT.Date
GROUP BY Year, Month, Day;

DROP VIEW IF EXISTS NutritionEventsWeekTotal;

CREATE VIEW NutritionEventsWeekTotal
AS
SELECT
	Min(Year)                          AS Year,
	Min(Week)                          AS Week,
	WeekStart,
	DATEDIFF(MAX(Date), MIN(Date)) + 1 AS Days,
	SUM(Calories)                      AS Calories,
	SUM(Protein)                       AS Protein,
	SUM(Fat)                           AS Fat,
	SUM(Saturated)                     AS Saturated,
	SUM(Carbohydrate)                  AS Carbohydrate,
	SUM(Sugar)                         AS Sugar,
	SUM(Fibre)                         AS Fibre,
	SUM(Cholesterol)                   AS Cholesterol,
	SUM(Salt)                          AS Salt,
	SUM(Units)                         AS Units,
	MIN(Kilos)                         AS MinKilos,
	CAST(AVG(Kilos) AS DECIMAL(10, 1)) AS AvgKilos,
	MAX(Kilos)                         AS MaxKilos,
	MAX(Kilos) - MIN(Kilos)            AS RangeKilos
FROM NutritionEventSummary
GROUP BY WeekStart;

DROP VIEW IF EXISTS NutritionEventsWeekly;

CREATE VIEW NutritionEventsWeekly
AS
SELECT
	EN.*,
	WT.Kilos,
	BMI(WT.Kilos)                               AS BMI,
	Days * 2500 - Calories                      AS Remaining,
	CAST(Calories     / Days AS DECIMAL(10, 1)) AS DailyCalories,
	CAST(Protein      / Days AS DECIMAL(10, 1)) AS DailyProtein,
	CAST(Fat          / Days AS DECIMAL(10, 1)) AS DailyFat,
	CAST(Saturated    / Days AS DECIMAL(10, 1)) AS DailySaturated,
	CAST(Carbohydrate / Days AS DECIMAL(10, 1)) AS DailyCarbohydrate,
	CAST(Sugar        / Days AS DECIMAL(10, 1)) AS DailySugar,
	CAST(Fibre        / Days AS DECIMAL(10, 1)) AS DailyFibre,
	CAST(Cholesterol  / Days AS DECIMAL(10, 1)) AS DailyCholesterol,
	CAST(Salt         / Days AS DECIMAL(10, 1)) AS DailySalt,
	CAST(Units        / Days AS DECIMAL(10, 1)) AS DailyUnits,
	CAST(CalculateCalories(Fat, Carbohydrate, Protein, Units) / Days AS DECIMAL) AS EstimatedCalories
FROM NutritionEventsWeekTotal  EN
LEFT JOIN Weight               WT
ON EN.WeekStart = WT.Date;

DROP VIEW IF EXISTS NutritionRecordFull;

CREATE VIEW NutritionRecordFull
AS
SELECT
	NE.Timestamp,
	Year(NE.Timestamp)                                   AS Year,
	Month(NE.Timestamp)                                  AS Month,
	Day(NE.Timestamp)                                    AS Day,
	Week(NE.Timestamp) + 1                               AS Week,
	Weekday(NE.Timestamp)                                AS Weekday,
	NE.Description,
	NI.Item,
	NI.Source,
	NI.Type,
	CAST(NR.Quantity AS DECIMAL(6, 2))                   AS Quantity,
	CAST(NR.ABV      AS DECIMAL(4, 1))                   AS ABV,	
	NR.IsComposite, 
	NI.Simple,
    NI.IsVolume,
	NI.Calories                                          AS ICalories,
	NI.Protein                                           AS IProtein,
	NI.Fat                                               AS IFat,
	NI.Saturated                                         AS ISaturated,
	NI.Carbohydrate                                      AS ICarbohydrate,
	NI.Sugar                                             AS ISugar,
	NI.Fibre                                             AS IFibre,
	NI.Cholesterol                                       AS ICholesterol,
	NI.Salt                                              AS ISalt,
	NI.DefaultSize,
	NI.ABV                                               AS DefaultABV,
	CAST(NR.Quantity * NI.Calories     AS DECIMAL(5, 1)) AS Calories,
	CAST(NR.Quantity * NI.Protein      AS DECIMAL(5, 1)) AS Protein,
	CAST(NR.Quantity * NI.Fat          AS DECIMAL(5, 1)) AS Fat,
	CAST(NR.Quantity * NI.Saturated    AS DECIMAL(5, 1)) AS Saturated,
	CAST(NR.Quantity * NI.Carbohydrate AS DECIMAL(5, 1)) AS Carbohydrate,
	CAST(NR.Quantity * NI.Sugar        AS DECIMAL(5, 1)) AS Sugar,
	CAST(NR.Quantity * NI.Fibre        AS DECIMAL(5, 1)) AS Fibre,
	CAST(NR.Quantity * NI.Cholesterol  AS DECIMAL(5, 1)) AS Cholesterol,
	CAST(NR.Quantity * NI.Salt         AS DECIMAL(5, 1)) AS Salt,
	CAST(NR.Quantity * NI.ABV / 1000   AS DECIMAL(5, 1)) AS Units
FROM NutritionEvent  NE
JOIN NutritionRecord NR
ON NE.Timestamp = NR.Timestamp
JOIN NutritionItem NI
ON  NR.Item      = NI.Item
AND NR.Source    = NI.Source
AND NR.Timestamp BETWEEN NI.Start AND NI.End
AND (NR.IsComposite = 'Y' AND NI.Simple = 'C' OR COALESCE(NR.IsComposite, 'N') = 'N' AND NI.Simple <> 'C');

DROP VIEW IF EXISTS CalculatedDetails;

CREATE VIEW CalculatedDetails
AS
SELECT 
	Item,
	Type,
	Source,
	Start,
	Calories,
	CalculateCalories(Fat, Carbohydrate, Protein, ABV / 1000) AS CalculatedCalories,
	Protein,
	Fat,
	Saturated,
	Carbohydrate,
	Sugar,
	Fibre,
	Salt,
	ABV,
	56 * ABV / 1000 AS AlcoholCalaries,
	Simple,
	CAST(100 * CalculateCalories(Fat, Carbohydrate, Protein, ABV / 1000) / calories AS DECIMAL(12, 1)) AS Diff
FROM NutritionDetail
WHERE Calories <> 0

