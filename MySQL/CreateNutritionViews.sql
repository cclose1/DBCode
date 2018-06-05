
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
	PackSize
FROM NutritionDetail
UNION
SELECT
	NC.Item,
	MIN(NC.Type)                  AS Type,
	NC.Source,
	NC.Start,
	MIN(NC.End)                   AS End,
	MIN(NC.Modified)              AS Modified,
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
ON  NR.Timestamp BETWEEN ND.Start AND ND.End
AND NR.Item   = ND.Item
AND NR.Source = ND.Source
GROUP BY NC.Start, NC.Item, NC.Source;

DROP VIEW IF EXISTS NutritionEventSummaryOld;

CREATE VIEW NutritionEventSummaryOld
AS
SELECT
	EV.Timestamp,
	CAST(EV.Timestamp AS Date)                 AS Date,
	Year(EV.Timestamp)                         AS Year,
	Month(EV.Timestamp)                        AS Month,
	Day(EV.Timestamp)                          AS Day,
	Week(EV.Timestamp) + 1                     AS Week,
	SubStr(DayName(EV.Timestamp), 1, 3)        AS Weekday,
	'New'             AS Type,
	Min(Description)  AS Description,
	Min(Comment)      AS Comment,
	Count(*)                           AS Items,
	SUM(Quantity)                      AS Quantity,
	CAST(SUM(Quantity * Calories)      AS DECIMAL(12, 1)) AS Calories,
	CAST(SUM(Quantity * Protein)       AS DECIMAL(12, 1)) AS Protein,
	CAST(SUM(Quantity * Fat)           AS DECIMAL(12, 1)) AS Fat,
	CAST(SUM(Quantity * Saturated)     AS DECIMAL(12, 1)) AS Saturated,
	CAST(SUM(Quantity * Carbohydrate)  AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(SUM(Quantity * Sugar)         AS DECIMAL(12, 1)) AS Sugar,
	CAST(SUM(Quantity * Fibre)         AS DECIMAL(12, 1)) AS Fibre,
	CAST(SUM(Quantity * Cholesterol)   AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(SUM(Quantity * Salt)          AS DECIMAL(12, 1)) AS Salt,
	CAST(SUM(Quantity * NR.ABV / 1000) AS DECIMAL(12, 1)) AS Units
FROM NutritionEvent  EV
LEFT JOIN NutritionRecord NR
ON EV.Timestamp = NR.Timestamp
LEFT JOIN NutritionDetail ND
ON  NR.Item   = ND.Item
AND NR.Source = ND.Source
GROUP BY EV.Timestamp;

DROP VIEW IF EXISTS NutritionEventSummary;

CREATE VIEW NutritionEventSummary
AS
SELECT
	EV.Timestamp,
	CAST(EV.Timestamp AS Date)                            AS Date,
	Year(EV.Timestamp)                                    AS Year,
	Month(EV.Timestamp)                                   AS Month,
	Day(EV.Timestamp)                                     AS Day,
	Week(EV.Timestamp) + 1                                AS Week,
	SubStr(DayName(EV.Timestamp), 1, 3)                   AS Weekday,
	'New'                                                 AS Type,
	Min(Description)                                      AS Description,
	Min(Comment)                                          AS Comment,
	Count(*)                                              AS Items,
	SUM(Quantity)                                         AS Quantity,
	CAST(SUM(Quantity * Calories)      AS DECIMAL(12, 1)) AS Calories,
	CAST(SUM(Quantity * Protein)       AS DECIMAL(12, 1)) AS Protein,
	CAST(SUM(Quantity * Fat)           AS DECIMAL(12, 1)) AS Fat,
	CAST(SUM(Quantity * Saturated)     AS DECIMAL(12, 1)) AS Saturated,
	CAST(SUM(Quantity * Carbohydrate)  AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(SUM(Quantity * Sugar)         AS DECIMAL(12, 1)) AS Sugar,
	CAST(SUM(Quantity * Fibre)         AS DECIMAL(12, 1)) AS Fibre,
	CAST(SUM(Quantity * Cholesterol)   AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(SUM(Quantity * Salt)          AS DECIMAL(12, 1)) AS Salt,
	CAST(SUM(Quantity * NR.ABV / 1000) AS DECIMAL(12, 1)) AS Units
FROM NutritionEvent  EV
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
	CAST(Timestamp AS DATE) AS Date,
	Year(Timestamp)                      AS Year,
	Month(Timestamp)                     AS Month,
	Day(Timestamp)                       AS Day,
	Week(Timestamp) + 1                  AS Week,
	SubStr(DayName(Timestamp), 1, 3)     AS Weekday,
	'Old'                                AS Type,
	Description,
	NULL                                 AS Comment,
	NULL                                 AS Items,
	NULL                                 AS Quantity,
	CAST(Calories     AS DECIMAL(12, 1)) AS Calories,
	CAST(Fat          AS DECIMAL(12, 1)) AS Protein,
	CAST(Fat          AS DECIMAL(12, 1)) AS Fat,
	CAST(Saturated    AS DECIMAL(12, 1)) AS Saturated,
	CAST(Carbohydrate AS DECIMAL(12, 1)) AS Carbohydrate,
	CAST(Sugar        AS DECIMAL(12, 1)) AS Sugar,
	CAST(Fibre        AS DECIMAL(12, 1)) AS Fibre,
	CAST(Cholesterol  AS DECIMAL(12, 1)) AS Cholesterol,
	CAST(Salt         AS DECIMAL(12, 1)) AS Salt,
	CAST(Units        AS DECIMAL(12, 1)) AS Units
FROM NutritionHistorical;

DROP VIEW IF EXISTS NutritionEventsDaily;

CREATE VIEW NutritionEventsDaily
AS
SELECT
	Year,
	Month,
	Day,
	MIN(EN.Date)                 AS Date,
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
	SUM(Units)                   AS Units,
	WT.Kilos
FROM NutritionEventSummary     EN
LEFT JOIN Weight               WT
ON EN.Date = WT.Date
GROUP BY Year, Month, Day;

DROP VIEW IF EXISTS NutritionEventsWeekTotal;

CREATE VIEW NutritionEventsWeekTotal
AS
SELECT
	Year,
	Week,
	MIN(Date)                          AS Date,
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
	SUM(Units)                         AS Units
FROM NutritionEventSummary
GROUP BY Year, Week;

DROP VIEW IF EXISTS NutritionEventsWeekly;

CREATE VIEW NutritionEventsWeekly
AS
SELECT
	EN.*,
	WT.Kilos,
	CAST(Calories     / Days AS DECIMAL(10, 1)) AS DailyCalories,
	CAST(Protein      / Days AS DECIMAL(10, 1)) AS DailyProtein,
	CAST(Fat          / Days AS DECIMAL(10, 1)) AS DailyFat,
	CAST(Saturated    / Days AS DECIMAL(10, 1)) AS DailySaturated,
	CAST(Carbohydrate / Days AS DECIMAL(10, 1)) AS DailyCarbohydrate,
	CAST(Sugar        / Days AS DECIMAL(10, 1)) AS DailySugar,
	CAST(Fibre        / Days AS DECIMAL(10, 1)) AS DailyFibre,
	CAST(Cholesterol  / Days AS DECIMAL(10, 1)) AS DailyCholesterol,
	CAST(Salt         / Days AS DECIMAL(10, 1)) AS DailySalt,
	CAST(Units        / Days AS DECIMAL(10, 1)) AS DailyUnits
FROM NutritionEventsWeekTotal  EN
LEFT JOIN Weight               WT
ON EN.Date = WT.Date;

DROP VIEW IF EXISTS NutritionRecordFull;

CREATE VIEW NutritionRecordFull
AS
SELECT
	NE.Timestamp,
	Year(NE.Timestamp)                         AS Year,
	Month(NE.Timestamp)                        AS Month,
	Day(NE.Timestamp)                          AS Day,
	Week(NE.Timestamp) + 1                     AS Week,
	Weekday(NE.Timestamp)                      AS Weekday,
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
	4 * (COALESCE(Protein, 0) + COALESCE(Carbohydrate, 0)) + 9 * COALESCE(Fat, 0) + 56 * COALESCE(ABV, 0) / 1000 AS CalculatedCalories,
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
	CAST(100 * 4 * (COALESCE(Protein, 0) + COALESCE(Carbohydrate, 0)) + 9 * COALESCE(Fat, 0) + 56 * COALESCE(ABV, 0) / 1000 / Calories AS DECIMAL) AS Diff
FROM NutritionDetail;


