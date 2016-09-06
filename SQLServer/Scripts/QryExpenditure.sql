DECLARE @days   AS INT        = 0
DECLARE @amount AS SMALLMONEY = 0

/*
SELECT
	*
FROM Expenditure.dbo.OldAnalyse(NULL, @days, @amount)
WHERE Month IN (2, 3, 4, 5, 6, 7, 8, 9)
AND   Year  =  2014
SELECT
	* Expenditure.dbo.AnalyseNew(-5, @amount)
WHERE Month IN (2, 3, 4, 5, 6, 7, 8, 9)
AND   Year  =  2014
*/
SELECT
	*,
	CURRENT_TIMESTAMP
FROM Expenditure.dbo.Analyse(@days, @amount)
ORDER BY Year DESC, Month DESC
