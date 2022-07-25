
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
