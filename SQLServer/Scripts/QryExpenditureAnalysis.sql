USE Expenditure

SELECT 
	Year,
	Month,
	Type,
	SUM(Amount) AS Amount,
	SUM(BankCorrection) AS BankCorrection
FROM Expenditure.dbo.Spend
WHERE Period IS NULL OR Period <> 'Y'
GROUP BY Year, Month, Type
ORDER BY Year DESC, Month DESC

SELECT 
	Year,
	Month,
	SUM(Amount) AS Amount,
	SUM(BankCorrection) AS BankCorrection
FROM Expenditure.dbo.Spend
WHERE Period IS NULL OR Period <> 'Y'
GROUP BY Year, Month
ORDER BY Year DESC, Month DESC

SELECT 
	Year,
	Month,
	Category,
	SUM(Amount) AS Amount,
	SUM(BankCorrection) AS BankCorrection
FROM Expenditure.dbo.Spend
WHERE (Period IS NULL OR Period <> 'Y')
AND Category IN ('Discretionary', 'Essential')
GROUP BY Year, Month, Category
ORDER BY Year DESC, Month DESC, Category