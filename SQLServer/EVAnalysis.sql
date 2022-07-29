USE Expenditure
GO

SELECT
	*
FROM      Expenditure.dbo.ChargeSession CS
LEFT JOIN Expenditure.dbo.ChargeStats   ST
ON CS.Start = ST.Start

SELECT
	CS.Start  AS CStart,
	ST.Start  AS SStart,
	CAST(DATEDIFF(ss, CS.Start, CS.[End])/3600.0 AS DECIMAL(9, 5)) AS CHours,
	ST.Hours  AS SHours,
	CS.[End]  AS CEnd,
	ST.[End]  AS SEnd,
	CS.Charge AS CCharge,
	ST.Charge AS SCharge
FROM      Expenditure.dbo.ChargeSession CS
LEFT JOIN Expenditure.dbo.ChargeStats   ST
ON CS.Start = ST.Start


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
