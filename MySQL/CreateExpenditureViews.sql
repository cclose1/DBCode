DROP VIEW IF EXISTS ListValues;

CREATE VIEW ListValues
AS
SELECT
	'Payment' AS Type,
	Code      AS Value
FROM PaymentSource
UNION
SELECT DISTINCT
	'Category' AS Type,
	Category   AS Value
FROM SpendData
UNION
SELECT DISTINCT
	'Type'     AS Type,
	Type       AS Value
FROM SpendData;

DROP VIEW IF EXISTS Spend;

CREATE VIEW Spend AS 
SELECT 
	SeqNo,
	Modified,
	IncurredBy,
	Timestamp,
	CAST(Timestamp AS Date)        AS Date,
	CAST(Timestamp AS Time)        AS Time,
	Year(Timestamp)                AS Year,
	Month(Timestamp)               AS Month,
	DayOfMonth(Timestamp)          AS Day,
	Week(Timestamp,0)              AS Week,
	SUBSTR(DAYNAME(Timestamp),1,3) AS Weekday,
	CASE
		WHEN DAYOFWEEK(Timestamp) = 2 THEN DAYOFYEAR(Timestamp)
		WHEN DAYOFWEEK(Timestamp) = 3 THEN DAYOFYEAR(DATE_ADD(Timestamp, INTERVAL -1 DAY))
		WHEN DAYOFWEEK(Timestamp) = 4 THEN DAYOFYEAR(DATE_ADD(Timestamp, INTERVAL -2 DAY))
		WHEN DAYOFWEEK(Timestamp) = 5 THEN DAYOFYEAR(DATE_ADD(Timestamp, INTERVAL -3 DAY))
		WHEN DAYOFWEEK(Timestamp) = 6 THEN DAYOFYEAR(DATE_ADD(Timestamp, INTERVAL -4 DAY))
		WHEN DAYOFWEEK(Timestamp) = 7 THEN DAYOFYEAR(DATE_ADD(Timestamp, INTERVAL -5 DAY))
		WHEN DAYOFWEEK(Timestamp) = 1 THEN DAYOFYEAR(DATE_ADD(Timestamp, INTERVAL -6 DAY))
		ELSE -1
	END FirstWeekday,
	Category,
	Type,
	Amount,
	Description,
	Location,
	Period,
	`Ignore`,
	Payment,
	IFNULL(BankCorrection, '') AS BankCorrection
from SpendData;

DROP VIEW IF EXISTS TransactionLineWithCurrency;

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
AND CAST(TL.Timestamp AS Date) = CR.Date;

DROP VIEW IF EXISTS CurrentAccount;

CREATE VIEW CurrentAccount
AS
SELECT
	*
FROM Account
WHERE CURRENT_TIMESTAMP BETWEEN Start AND IFNULL(End, '3000-01-01');

DROP VIEW IF EXISTS BankTransactions;

CREATE VIEW BankTransactions
AS
SELECT
	TL.TXNId,
    THL.Start      AS TXNCreated,
    TH.Description AS TXNDescription,
    TL.Line,
	TL.Timestamp,
    TL.Completed,
	BK.Bank,
	BK.SortCode,
	TL.Account,
    TL.Fee,
	AC.AccountNumber,
	AC.CardNumber,
	AC.Description AS AccountDescription,
	TL.Amount,
	TL.Currency,
    TL.Type,
    TL.`Usage`,
    TL.CryptoAddress,
	TL.Description
FROM TransactionLine TL
LEFT JOIN Account    AC
ON   TL.Account    = AC.Code
AND  TL.Timestamp  BETWEEN AC.Start AND IFNULL(End, '01-Jan-3000')
LEFT JOIN Bank       BK
ON   AC.Bank       = BK.Code
LEFT JOIN TransactionHeader TH
ON TL.TXNId = TH.TXNId
LEFT JOIN (
	SELECT
		TXNId,
		Min(Timestamp) AS Start
	FROM TransactionLine
	GROUP BY TXNId) THL
ON TL.TXNId = THL.TXNId;

DROP VIEW IF EXISTS SpendTransactions;

CREATE VIEW SpendTransactions
AS
SELECT
	SD.SeqNo, 
	SD.Timestamp,
	SD.Description,
	SD.Location,
	SD.Amount,
	SD.Payment                               AS PaymentCode,
	SD.Amount + IFNULL(SD.BankCorrection, 0) AS BankAmount,
	IFNULL(SD.BankCorrection ,0)             AS Correction,
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
WHERE Payment <> 'Cash';

DROP VIEW IF EXISTS DailyCurrencyRates;

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
GROUP BY Date, Source, Target;

DROP VIEW IF EXISTS MergeTransactionLines;

CREATE VIEW MergeTransactionLines
AS
SELECT
	TXNId,
	ROW_NUMBER() OVER (PARTITION BY TXNId ORDER BY Currency) AS `Index`,
    Min(Line)                                                AS Line,
	Min(Timestamp)                                           AS Timestamp,
	Min(Description)                                         AS Description,
	Currency,
	Account,
	Min(Type)                                                AS Type,
	Min(`Usage`)                                             AS `Usage`,
	Count(*)                                                 AS `Lines`,
	Sum(Amount)                                              AS Amount,
	Sum(Fee)                                                 AS Fee
FROM TransactionLine TL
GROUP BY TXNId, Account, Currency;

DROP VIEW IF EXISTS BankTransfers;

CREATE VIEW BankTransfers
AS
SELECT
	TH.TXNId,
	CASE WHEN TH.Created > J1.Timestamp OR TH.Created IS NULL THEN J1.Timestamp ELSE TH.Created END AS Created,
	TH.Description,
	Type,
	`Usage`,
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
		LEAST(LN1.Timestamp, LN2.Timestamp) AS Timestamp,
		LN1.Type,
		LN1.Usage,
		LN1.Account                         AS SrcAccount,
		LN1.Amount                          AS SrcAmount,
		LN1.Fee                             AS SrcFee,
		LN1.Currency                        AS SrcCurrency,
		LN1.Description                     AS SrcDescription,
		LN1.Timestamp                       AS TrgTimestamp,
		LN2.Account                         AS TrgAccount,
		LN2.Amount                          AS TrgAmount,
		LN2.Fee                             AS TrgFee,
		LN2.Currency                        AS TrgCurrency,
		LN2.Description                     AS TrgDescription
	FROM MergeTransactionLines LN1
	LEFT JOIN MergeTransactionLines LN2
	ON  LN1.TXNId = LN2.TXNId
	WHERE LN1.Line  = 1
	AND   LN2.Line <> 1) J1
JOIN TransactionHeader TH
ON J1.TXNId = TH.TXNId;

DROP VIEW IF EXISTS CurrentExchangeValue;

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
	CAST(TL.Amount * DR.AvgRate - TL.ExcAmount AS DECIMAL(10, 2)) AS `Change`
FROM TransactionLineWithCurrency TL
JOIN DailyCurrencyRates DR
ON  TL.Currency    = DR.Source
AND TL.ExcCurrency = DR.Target
AND DR.Date        = CURDATE();

DROP VIEW IF EXISTS ReminderState;

CREATE VIEW ReminderState
AS
SELECT
	*,
    TIMESTAMPDIFF(DAY, CURRENT_TIMESTAMP, Timestamp) AS  Remaining,
	CASE WHEN CURRENT_TIMESTAMP BETWEEN DATE_ADD(Timestamp, INTERVAL -COALESCE(Warndays, 5) DAY) AND Timestamp AND Suspended <> 'Y' THEN 'Y' ELSE 'N' END AS Alert
FROM Reminder;