
DROP VIEW Spend
GO

CREATE VIEW Spend AS
SELECT
	SeqNo,
--	CONVERT(VARCHAR(19), Modified,  120)          AS Modified,
	Modified,
	IncurredBy,
--	CONVERT(VARCHAR(19), Timestamp, 120)          AS Timestamp,
	Timestamp,
	CAST(Timestamp AS Date)                       AS Date,
	CONVERT(VARCHAR(8),Timestamp,108)             AS Time,
	DATEPART(YYYY, Timestamp)                     AS Year,
	DATEPART(M, Timestamp)                        AS Month,
	DATEPART(D, Timestamp)                        AS Day,
	DATEPART(WEEK, Timestamp)                     AS Week,
	SUBSTRING(DATENAME(WEEKDAY, Timestamp), 1, 3) AS Weekday,
	CASE
		WHEN DATEPART(WEEKDAY, Timestamp) = 2 THEN DATEPART(DAYOFYEAR, Timestamp)
		WHEN DATEPART(WEEKDAY, Timestamp) = 3 THEN DATEPART(DAYOFYEAR, DATEADD(D, -1, Timestamp))
		WHEN DATEPART(WEEKDAY, Timestamp) = 4 THEN DATEPART(DAYOFYEAR, DATEADD(D, -2, Timestamp))
		WHEN DATEPART(WEEKDAY, Timestamp) = 5 THEN DATEPART(DAYOFYEAR, DATEADD(D, -3, Timestamp))
		WHEN DATEPART(WEEKDAY, Timestamp) = 6 THEN DATEPART(DAYOFYEAR, DATEADD(D, -4, Timestamp))
		WHEN DATEPART(WEEKDAY, Timestamp) = 7 THEN DATEPART(DAYOFYEAR, DATEADD(D, -5, Timestamp))
		WHEN DATEPART(WEEKDAY, Timestamp) = 1 THEN DATEPART(DAYOFYEAR, DATEADD(D, -6, Timestamp))
		ELSE -1
	END FirstWeekday,
	Category,
	Type,
	Amount,
	Description,
	Location,
	Period,
	"Ignore",
	Payment,
	ISNULL(BankCorrection, '') AS BankCorrection
FROM dbo.SpendData
GO

DROP VIEW CurrentAccount
GO

CREATE VIEW CurrentAccount
AS
SELECT
	*
FROM Account
WHERE CURRENT_TIMESTAMP BETWEEN Start AND ISNULL([End], '01-Jan-3000')
GO

DROP VIEW BankTransactions
GO

CREATE VIEW BankTransactions
AS
SELECT
	TH.TXNId,
	THL.Start      AS TXNCreated,
	TH.Description AS TXNDescription,
	TL.Line,
	TL.Timestamp,
	TL.Completed,
	BK.Bank,
	BK.SortCode,
	TL.Account,
	AC.AccountNumber,
	AC.CardNumber,
	AC.Description AS AccountDescription,
	TL.Amount,
	TL.Fee,
	TL.Currency,
	TL.Type,
	TL.Usage,
	TL.CryptoAddress,
	TL.Description
FROM TransactionLine TL
LEFT JOIN Account    AC
ON   TL.Account  = AC.Code
AND  TL.Timestamp BETWEEN AC.Start AND ISNULL(AC.[End], '01-Jan-3000')
LEFT JOIN Bank       BK
ON   AC.Bank     = BK.Code
LEFT JOIN TransactionHeader TH
ON   TL.TXNId = TH.TXNId
LEFT JOIN (
	SELECT
		TXNId,
		Min(Timestamp) AS Start
	FROM TransactionLine
	GROUP BY TXNId) THL
ON TL.TXNId = THL.TXNId
GO

DROP VIEW SpendTransactions
GO

CREATE VIEW SpendTransactions
AS
SELECT
	SD.SeqNo, 
	SD.Timestamp,
	SD.Description,
	SD.Location,
	SD.Amount,
	SD.Payment                               AS PaymentCode,
	SD.Amount + ISNULL(SD.BankCorrection, 0) AS BankAmount,
	ISNULL(SD.BankCorrection ,0)             AS Correction,
	PS.Type,
	BK.Bank,
	BK.SortCode,
	AC.AccountNumber,
	AC.CardNumber,
	AC.Owner
FROM SpendData          SD
LEFT JOIN PaymentSource PS
ON   SD.Payment       = PS.Code
LEFT JOIN Account       AC
ON   PS.Account       = AC.Code
LEFT JOIN Bank          BK
ON   AC.Bank          = BK.Code
WHERE Payment <> 'Cash'
GO

DROP VIEW BankTransactionsSummary
GO

CREATE VIEW BankTransactionsSummary
AS
SELECT
	Account,
	Currency,
	Usage,
	SUM(Amount)                       AS Amount,
	SUM(IsNull(Fee, 0))               AS Fee,
	SUM(Amount) - SUM(IsNull(Fee, 0)) AS Total,
	Count(*)                          AS Count
FROM Expenditure.dbo.TransactionLine
GROUP BY Account, Currency, Usage
GO

DROP VIEW DailyCurrencyRates
GO

CREATE VIEW DailyCurrencyRates
AS
SELECT
	Date,
	Source,
	Target,
	Count(*)  AS Count,
	CAST(Min(Rate) AS DECIMAL(12, 4)) AS MinRate,
	CAST(Avg(Rate) AS DECIMAL(12, 4)) AS AvgRate,
	CAST(Max(Rate) AS DECIMAL(12, 4)) AS MaxRate
FROM (
	SELECT
		CAST(Created AS Date) AS Date,
		CASE WHEN Source = 'BTC' THEN 'mBTC' ELSE Source END AS Source,
		CASE WHEN Target = 'BTC' THEN 'mBTC' ELSE Target END AS Target,
		CASE 
			WHEN Source = 'BTC' THEN Rate / 1000
			WHEN Target = 'BTC' THEN Rate * 1000 
			ELSE Rate
		END AS Rate,
		Rate AS RateO
	FROM CurrencyRate) J1
GROUP BY Date, Source, Target

GO

DROP VIEW MergeTransactionLines
GO
/*
CREATE VIEW MergeTransactionLines
AS
SELECT
	TXNId,
	ROW_NUMBER() OVER (PARTITION BY TXNId ORDER BY Currency, Line) AS Line,
	Min(Timestamp)                                                 AS Timestamp,
	Min(Description)                                               AS Description,
	Currency,
	Account,
	Type,
	Usage,
	Count(*)                                                       AS Lines,
	Sum(Amount)                                                    AS Amount,
	Sum(Fee)                                                       AS Fee
FROM TransactionLine
GROUP BY TXNId, Account, Currency, Line, Type, Usage
GO
*/
CREATE VIEW MergeTransactionLines
AS
SELECT
	ROW_NUMBER() OVER (PARTITION BY TXNId ORDER BY Currency) AS [Index],
	TXNId,
	Min(Line)                                                AS Line,
	Min(Timestamp)                                           AS Timestamp,
	Min(Description)                                         AS Description,
	Currency,
	Account,
	Min(Type)                                                AS Type,
	Min(Usage)                                               AS Usage,
	Count(*)                                                 AS Lines,
	Sum(Amount)                                              AS Amount,
	Sum(Fee)                                                 AS Fee
FROM TransactionLine
GROUP BY TXNId, Account, Currency
GO

DROP VIEW BankTransfers
GO

CREATE VIEW BankTransfers
AS
SELECT
	TH.TXNId,
	CASE WHEN TH.Created > J1.Timestamp OR TH.Created IS NULL THEN J1.Timestamp ELSE TH.Created END AS Created,
	TH.Description,
	Type,
	Usage,
	SrcAccount,
	SrcAmount,
	SrcFee,
	SrcCurrency,
	TrgAccount,
	TrgAmount,
	TrgFee,
	TrgCurrency
FROM (
	SELECT
		LN1.TXNId, 
		(
			SELECT MIN(C) FROM (VALUES (LN1.Timestamp), (LN2.Timestamp)) AS v (C)) AS Timestamp,
		LN1.Type,
		LN1.Usage,
		LN1.Account     AS SrcAccount,
		LN1.Amount      AS SrcAmount,
		LN1.Fee         AS SrcFee,
		LN1.Currency    AS SrcCurrency,
		LN1.Description AS SrcDescription,
		LN1.Timestamp   AS TrgTimestamp,
		LN2.Account     AS TrgAccount,
		LN2.Amount      AS TrgAmount,
		LN2.Fee         AS TrgFee,
		LN2.Currency    AS TrgCurrency,
		LN2.Description AS TrgDescription
	FROM MergeTransactionLines LN1
	LEFT JOIN MergeTransactionLines LN2
	ON  LN1.TXNId = LN2.TXNId
	WHERE LN1.Line  = 1
	AND   LN2.Line <> 1) J1
JOIN TransactionHeader TH
ON J1.TXNId = TH.TXNId
GO
DROP VIEW TransactionLineWithCurrency
GO
CREATE VIEW TransactionLineWithCurrency
AS
SELECT 
	TL.TXNId,
	TL.Timestamp, 
	TL.Account,
	TL.Currency,
	TL.Amount,
	TL.Fee,
	TL.Amount * CR.AvgRate AS ExcAmount,
	CR.Target              AS ExcCurrency,
	CR.MinRate,
	CR.AvgRate,
	CR.MaxRate
FROM TransactionLine TL
LEFT JOIN DailyCurrencyRates CR
ON  TL.Currency                = CR.Source
AND CAST(TL.Timestamp AS Date) = CR.Date
GO

DROP VIEW CurrentExchangeValue
GO
CREATE VIEW CurrentExchangeValue
AS
SELECT
	TL.TXNId,
	TL.Timestamp,
	TL.Account,
	TL.Currency,
	CAST(TL.Amount              AS DECIMAL(10, 2))                AS Amount,
	CAST(TL.ExcAmount           AS DECIMAL(10, 2))                AS ExcAmount,
	TL.ExcCurrency,
	CAST(TL.Amount * DR.AvgRate AS DECIMAL(10, 2))                AS CurrentAmount,
	CAST(TL.Amount * DR.AvgRate - TL.ExcAmount AS DECIMAL(10, 2)) AS Change
FROM TransactionLineWithCurrency TL
JOIN DailyCurrencyRates DR
ON  TL.Currency    = DR.Source
AND TL.ExcCurrency = DR.Target
AND DR.Date        = CAST(GETDATE() AS DATE)
GO

DROP VIEW ReminderState
GO
CREATE VIEW ReminderState
AS
SELECT
	*,
	DATEDIFF(DAY, CURRENT_TIMESTAMP,Timestamp) AS  Remaining,
	CASE WHEN CURRENT_TIMESTAMP BETWEEN DATEADD(DAY,-COALESCE(Warndays, 5), Timestamp) AND Timestamp AND Suspended <> 'Y' THEN 'Y' ELSE 'N' END AS Alert
FROM Reminder
GO