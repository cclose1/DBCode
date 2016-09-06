
DROP VIEW IF EXISTS NutritionEventSummaryNew;

CREATE VIEW NutritionEventSummaryNew
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
	NULL AS Comment,
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