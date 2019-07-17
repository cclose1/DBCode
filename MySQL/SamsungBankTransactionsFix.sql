USE Expenditure;

DROP VIEW IF EXISTS SpendTransactions;
DROP VIEW IF EXISTS BankTransactions;
DROP VIEW IF EXISTS TXNStart;

CREATE VIEW TXNStart
AS
SELECT
	TXNId,
	Min(Timestamp) AS Start
FROM TransactionLine
GROUP BY TXNId;

CREATE VIEW BankTransactions
AS
SELECT
	TL.TXNId,
    TS.Start       AS TXNCreated,
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
LEFT JOIN TXNStart TS
ON TL.TXNId = TS.TXNId;

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

