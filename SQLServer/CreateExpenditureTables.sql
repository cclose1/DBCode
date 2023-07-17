DROP VIEW Spend
GO
DROP VIEW SpendTransactions
GO
DROP VIEW CurrentAccount
GO
DROP VIEW BankTransactions
GO
DROP VIEW BankTransactionsSummary
GO
DROP VIEW DailyCurrencyRates
GO
DROP VIEW MergeTransactionLines
GO
DROP VIEW BankTransfers
GO
DROP View ReminderState
GO
DROP TABLE Currency
GO
DROP TABLE ListValues
GO
CREATE TABLE ListValues (
	Type  VARCHAR(8)  NOT NULL,
	Value VARCHAR(20) NOT NULL,
	PRIMARY KEY (Type ASC, Value ASC)
);
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

DROP TABLE CurrencyRate
GO
CREATE TABLE CurrencyRate(
	Created  DATETIME NOT NULL   DEFAULT CURRENT_TIMESTAMP,
	Source   CHAR(4)  NOT NULL,
	Target   CHAR(4)  NOT NULL,
	Provider VARCHAR(20),
	Rate     FLOAT(6),
	PRIMARY KEY (
		Created ASC,
		Source  ASC,
		Target  ASC)
);
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
	Start         DATETIME    NOT NULL,
	[End]         DATETIME    NULL,
	Code          VARCHAR(4)  NOT NULL,
	Bank          VARCHAR(4)  NOT NULL,
	AccountNumber VARCHAR(30) NULL,
	Type          VARCHAR(10) NOT NULL,
	CardNumber    VARCHAR(20) NULL,
	CardType      VARCHAR(20) NULL,
	Owner         VARCHAR(20) NULL,
	Description   VARCHAR(50) NULL,
	PRIMARY KEY (Start ASC, Code  ASC)
); 
GO

DROP TABLE SpendData
GO
CREATE TABLE SpendData (
  SeqNo          INT          IDENTITY(1, 1)      NOT NULL,
  Modified       DATETIME     NULL, 
  IncurredBy     VARCHAR(20)  DEFAULT 'Chris',
  Timestamp      DATETIME     NULL,
  Category       VARCHAR(15)  NULL,
  Type           VARCHAR(15)  NULL,
  Description    VARCHAR(max) NULL,
  Location       VARCHAR(max) NULL,
  Amount         SMALLMONEY   NULL,
  Monthly        CHAR(1)      NULL,
  Ignore         CHAR(1)      NULL,
  Period         CHAR(1)      NULL,
  Payment        VARCHAR(10)  NULL,
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

DROP TABLE TransactionHeader;
GO
CREATE TABLE TransactionHeader(
	SeqNo         INT              IDENTITY(1000, 1)      NOT NULL,
	Created       DATETIME         NULL,
	Modified      DATETIME         NULL, 
	TXNId         VARCHAR(15)      NULL,	
	Description   VARCHAR(max)     NULL,
	CONSTRAINT PKTransactionHeader PRIMARY KEY CLUSTERED(
		SeqNo  ASC)
)
GO
CREATE UNIQUE NONCLUSTERED INDEX TXNKey ON .TransactionHeader (
	TXNId ASC
)
GO
CREATE TRIGGER TransactionHeaderModified ON TransactionHeader AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TID
		SET Modified = CASE WHEN UPDATE(Modified) AND TID.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM TransactionHeader TID
	JOIN inserted 
	ON TID.SeqNo = inserted.SeqNo
END
GO
DROP TABLE TransactionLine;
GO
CREATE TABLE TransactionLine(
	SeqNo         INT              IDENTITY(1, 1)      NOT NULL,
	TXNId         VARCHAR(15)      NOT NULL,
	Line          INT              NOT NULL,
	Timestamp     DATETIME         NULL,
	Modified      DATETIME         NULL, 
	Completed     DATETIME         NULL,
	Account       DECIMAL(20, 13)  NULL,
	Fee           DECIMAL(20, 13)  NULL,
	Currency      VARCHAR(4)       NULL,
	Type          VARCHAR(15)      NULL,
	Usage         VARCHAR(10)      NULL,
	CryptoAddress VARCHAR(50)      NULL,
	Description   VARCHAR(max)     NULL,
	CONSTRAINT PKTransactionLine PRIMARY KEY CLUSTERED(
		TXNId  ASC,
		Line   ASC)
)
GO
CREATE TRIGGER TransactionLineModified ON TransactionLine AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TL
		SET Modified = CASE WHEN UPDATE(Modified) AND TL.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM TransactionLine TL
	JOIN inserted 
	ON  TL.TXNId = inserted.TXNId
	AND TL.Line = inserted.Line
END
GO
DROP TABLE Reminder
GO
CREATE TABLE Reminder (
	RefId		VARCHAR(10)   NOT NULL,
	Timestamp   DATETIME      NOT NULL,
	Type        VARCHAR(15)   NULL,
	Frequency   CHAR(1)       NULL,
	WarnDays    DECIMAL(3, 0) NULL,
	Suspended   VARCHAR(1)    NULL,
	Description VARCHAR(max)  NULL,
	Comment     VARCHAR(max)  NULL,
	PRIMARY KEY (RefId ASC)
)
GO
