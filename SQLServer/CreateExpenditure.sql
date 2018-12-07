DROP VIEW Spend
GO
DROP VIEW SpendTransactions
GO
DROP VIEW BankTransactions
GO

DROP TABLE Currency
GO
CREATE TABLE Currency (
	Designation VARCHAR(10) NOT NULL,
	Symbol      NVARCHAR(3)  NULL,
	Description VARCHAR(max),
	PRIMARY KEY (Designation ASC)
)
INSERT Currency VALUES ('GBP', '£', 'Pound Sterling');
INSERT Currency VALUES ('EUR', '€', 'Euro');
INSERT Currency VALUES ('USD', '$', 'United States Dollar');
INSERT Currency VALUES ('mBTC', NULL, 'milli Bitcoin');
INSERT Currency VALUES ('BTC', N'₿', 'Bitcoin');
GO
DROP TABLE Bank
GO
CREATE TABLE Bank(
	Code          VARCHAR(20) NOT NULL,
	Bank          VARCHAR(20) NOT NULL,
	SortCode      VARCHAR(8)  NOT NULL,
	PRIMARY KEY (Code  ASC)
); 
INSERT Bank VALUES ('HFX', 'Halifax',   '110854');
INSERT Bank VALUES ('SAN', 'Santander', '090128');
INSERT Bank VALUES ('REV', 'Revolut',   '236972');

GO
DROP TABLE BankTransactionType
GO
CREATE TABLE BankTransactionType(
	Code    VARCHAR(20) NOT NULL,
	Created DATETIME    DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (Code  ASC)
);
GO
INSERT BankTransactionType(Code) VALUES ('Credit');
INSERT BankTransactionType(Code) VALUES ('Debit');
INSERT BankTransactionType(Code) VALUES ('Transfer');
INSERT BankTransactionType(Code) VALUES ('Exchange');

GO
DROP TABLE AccountUsage 
GO
CREATE TABLE AccountUsage(
	Code    VARCHAR(20) NOT NULL,
	Created DATETIME    DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (Code  ASC)
);
GO
INSERT AccountUsage(Code) VALUES ('Crypto');
INSERT AccountUsage(Code) VALUES ('Meal');
INSERT AccountUsage(Code) VALUES ('Leisure');
INSERT AccountUsage(Code) VALUES ('Present');
INSERT AccountUsage(Code) VALUES ('Transport');
INSERT AccountUsage(Code) VALUES ('Food');
INSERT AccountUsage(Code) VALUES ('Travel');
INSERT AccountUsage(Code) VALUES ('Drinks');

DROP TABLE Account
GO
CREATE TABLE Account(
	Code          VARCHAR(4)  NOT NULL,
	Bank          VARCHAR(4)  NOT NULL,
	AccountNumber VARCHAR(30) NULL,
	Type          VARCHAR(10) NOT NULL,
	CardNumber    VARCHAR(20) NULL,
	CardType      VARCHAR(20) NULL,
	Owner         VARCHAR(20) NULL,
	Description   VARCHAR(50) NULL,
	PRIMARY KEY (Code  ASC)
); 
INSERT Account VALUES ('HF1', 'HFX', '00476796', 'Account', '4462 9140 6944 6719', 'Visa',       'Chris Close', 'Personal');
INSERT Account VALUES ('HF2', 'HFX', '11456266', 'Account', '4462 9136 0991 5188', 'Visa',       'Chris Close', 'Crypto Dealings');
INSERT Account VALUES ('HF3', 'HFX', '10264364', 'Account', NULL,                  NULL,         'Robyn Close', 'Personal');
INSERT Account VALUES ('SN1', 'SAN', '55360378', 'Account', '4547 4281 4410 8995', 'Visa',       'Joint',       'Household Expenditure');
INSERT Account VALUES ('SN2', 'SAN', NULL,       'Credit',  '5229 4899 6196 6222', 'MasterCard', 'Chris Close', 'Household Credit Card');
INSERT Account VALUES ('SN3', 'SAN', '65218889', 'Account', NULL,                  NULL,         'Robyn Close', 'Personal');
INSERT Account VALUES ('RV1', 'REV', '06037018', 'Account', '4596 5482 8140 7874', 'Visa',       'Chris Close', 'Personal');
INSERT Account VALUES ('RV2', 'REV', '06472777', 'Account', NULL,                  NULL,         'Robyn Close', 'Personal');
GO

DROP TABLE SpendData
GO
CREATE TABLE SpendData (
  SeqNo          INT          IDENTITY(1, 1)      NOT NULL,
  Modified       DATETIME     NULL, 
  IncurredBy     VARCHAR(20)  DEFAULT 'Chris',
  Timestamp      DATETIME     NULL,
  Category       VARCHAR(20)  NULL,
  Type           VARCHAR(20)  NULL,
  Description    VARCHAR(max) NULL,
  Location       VARCHAR(max) NULL,
  Amount         SMALLMONEY   NULL,
  Monthly        CHAR(1)      NULL,
  Ignore         CHAR(1)      NULL,
  Period         CHAR(1)      NULL,
  Payment        VARCHAR(30)  NULL,
  BankCorrection SMALLMONEY   DEFAULT NULL,
  CONSTRAINT PK_SpenData PRIMARY KEY CLUSTERED(
	SeqNo  ASC)
)
GO

CREATE TRIGGER SpendDataModified ON SpendData AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE SP
		SET Modified = CASE WHEN UPDATE(Modified) AND SP.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM SpendData SP
	JOIN inserted 
	ON SP.SeqNo = inserted.SeqNo
END
GO

DROP TABLE PaymentSource
GO
CREATE TABLE PaymentSource(
	Code    VARCHAR(20) NOT NULL,
	Account VARCHAR(20) NULL,
	Type    VARCHAR(20) NULL,
	Comment VARCHAR(max) NULL,
	PRIMARY KEY CLUSTERED (
		Code ASC
	)
)
GO

INSERT PaymentSource(Code, Account, Type) VALUES ('Cash',   NULL, NULL);
INSERT PaymentSource(Code, Account, Type) VALUES ('HCCSO', 'HF1', 'Standing Order');
INSERT PaymentSource(Code, Account, Type) VALUES ('HCCDD', 'HF1', 'Direct Debit');
INSERT PaymentSource(Code, Account, Type) VALUES ('HCCDC', 'HF1', 'Debit Card');
INSERT PaymentSource(Code, Account, Type) VALUES ('HCCCH', 'HF1', 'Cheque');
INSERT PaymentSource(Code, Account, Type) VALUES ('SJNSO', 'SN1', 'Standing Order');
INSERT PaymentSource(Code, Account, Type) VALUES ('SJNDD', 'SN1', 'Direct Debit');
INSERT PaymentSource(Code, Account, Type) VALUES ('SJNCC', 'SN2', 'Credit Card');
INSERT PaymentSource(Code, Account, Type) VALUES ('SRCSO', 'SN3', 'Standing Order');
INSERT PaymentSource(Code, Account, Type) VALUES ('SRCDD', 'SN3', 'Direct Debit');
INSERT PaymentSource(Code, Account, Type) VALUES ('SRCDC', 'SN3', 'Debit Card');
GO

DROP TABLE AccountTransaction;
GO
CREATE TABLE AccountTransaction(
	SeqNo       INT              IDENTITY(1, 1)      NOT NULL,
	Modified    DATETIME         NULL, 
	Timestamp   DATETIME         NULL,
	Completed   DATETIME         NULL,
	Account     VARCHAR(4)       NULL,
	Amount      DECIMAL(18, 6)   NULL,
	Fee         DECIMAL(18, 6)   NULL,
	Currency    VARCHAR(4)       NULL,
	Type        VARCHAR(15)      NULL,
	Usage       VARCHAR(10)      NULL,
	Description VARCHAR(max)     NULL,
	CONSTRAINT PKAccountTransaction PRIMARY KEY CLUSTERED(
		SeqNo  ASC)
)
GO
CREATE UNIQUE NONCLUSTERED INDEX TxnKey ON  AccountTransaction (
	Timestamp ASC,
	Account   ASC,
	Currency  ASC
)
GO
CREATE TRIGGER AccountTransactionModified ON AccountTransaction AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE AC
		SET Modified = CASE WHEN UPDATE(Modified) AND AC.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM AccountTransaction AC
	JOIN inserted 
	ON AC.SeqNo = inserted.SeqNo
END
GO
INSERT AccountTransaction(Timestamp, Account, Amount, Currency, Description) VALUES ('01-Jan-2018', 'HF1', 10.31, 'GBP', 'Test comment 1');
INSERT AccountTransaction(Timestamp, Account, Amount, Currency, Description) VALUES ('03-Jan-2018', 'HF1', 24.99, 'GBP', 'Test comment 2');
INSERT AccountTransaction(Timestamp, Account, Amount, Currency, Description) VALUES ('03-Jan-2018', 'RV1', 100,   'USD', 'Test comment 3');
INSERT AccountTransaction(Timestamp, Account, Amount, Currency, Description) VALUES ('03-Jan-2018', 'SN2', 300,   'GBP', 'Test comment 4');
GO
CREATE VIEW Spend AS
SELECT
	SeqNo,
	CONVERT(VARCHAR(19), Modified,  120)          AS Modified,
	IncurredBy,
	CONVERT(VARCHAR(19), Timestamp, 120)          AS Timestamp,
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

CREATE VIEW BankTransactions
AS
SELECT
	TX.SeqNo,
	TX.Timestamp,
	TX.Completed,
	BK.Bank,
	BK.SortCode,
	TX.Account,
	AC.AccountNumber,
	AC.CardNumber,
	TX.Amount,
	TX.Fee,
	TX.Currency,
	TX.Type,
	TX.Usage,
	TX.Description
FROM AccountTransaction TX
LEFT JOIN Account       AC
ON   TX.Account       = AC.Code
LEFT JOIN Bank          BK
ON   AC.Bank          = BK.Code
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

