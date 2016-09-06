CREATE VIEW Expenditure.ListValues
AS
SELECT
	'Payment' AS Type,
	Code      AS Value
FROM  Expenditure.PaymentSource
UNION
SELECT DISTINCT
	'Category' AS Type,
	Category   AS Value
FROM  Expenditure.SpendData
UNION
SELECT DISTINCT
	'Type' AS Type,
	Type   AS Value
FROM  Expenditure.SpendData;