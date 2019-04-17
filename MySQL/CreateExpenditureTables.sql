
DROP VIEW IF EXISTS Spend;
DROP VIEW IF EXISTS SpendTransactions;
DROP VIEW IF EXISTS BankTransactions;

DROP TABLE IF EXISTS Currency;

CREATE TABLE Currency (
	Designation VARCHAR(10) NOT NULL,
	Symbol      VARCHAR(3)  NULL,
	Description VARCHAR(1000),
	PRIMARY KEY (Designation ASC)
);

DROP TABLE IF EXISTS Bank;

CREATE TABLE Bank(
	Code          VARCHAR(20) NOT NULL,
	Bank          VARCHAR(20) NOT NULL,
	SortCode      VARCHAR(8)  NOT NULL,
	PRIMARY KEY (Code  ASC)
); 

DROP TABLE IF EXISTS BankTransactionType;

CREATE TABLE BankTransactionType(
	Code    VARCHAR(20) NOT NULL,
	Created DATETIME    DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (Code  ASC)
);

DROP TABLE IF EXISTS CurrencyRate;

CREATE TABLE CurrencyRate(
	Created  DATETIME NOT NULL   DEFAULT CURRENT_TIMESTAMP,
	Source   VARCHAR(4)  NOT NULL,
	Target   VARCHAR(4)  NOT NULL,
	Provider VARCHAR(20),
	Rate     FLOAT(6),
	PRIMARY KEY (
		Created ASC,
		Source  ASC,
		Target  ASC)
);

DROP TABLE IF EXISTS AccountUsage;

CREATE TABLE AccountUsage(
	Code    VARCHAR(20) NOT NULL,
	Created DATETIME    DEFAULT CURRENT_TIMESTAMP,
	PRIMARY KEY (Code  ASC)
);

DROP TABLE IF EXISTS Account;

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
DROP TABLE IF EXISTS SpendData;

CREATE TABLE SpendData (
  SeqNo          int(11)       NOT NULL AUTO_INCREMENT,
  Modified       Datetime(3)   DEFAULT NULL, 
  IncurredBy     VARCHAR(20)   DEFAULT 'Chris',
  Timestamp      datetime(3)   DEFAULT NULL,
  Category       varchar(20)   DEFAULT NULL,
  Type           varchar(20)   DEFAULT NULL,
  Description    varchar(1000) DEFAULT NULL,
  Location       varchar(1000) DEFAULT NULL,
  Amount         decimal(10,2) DEFAULT NULL,
  Monthly        char(1)       DEFAULT NULL,
  `Ignore`       char(1)       DEFAULT NULL,
  Period         char(1)       DEFAULT NULL,
  Payment        varchar(30)   DEFAULT NULL,
  BankCorrection decimal(10,2) DEFAULT NULL,
  PRIMARY KEY (SeqNo)
);

DELIMITER //

CREATE TRIGGER InsSpendData BEFORE INSERT ON SpendData
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdSpendData BEFORE UPDATE ON SpendData
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS AccountTransaction;

CREATE TABLE AccountTransaction(
	SeqNo         int(11)        NOT NULL AUTO_INCREMENT,
	Modified      DATETIME       NULL, 
	Timestamp     DATETIME       NULL,
	Completed     DATETIME       NULL,
    TXNId         VARCHAR(15)    NULL,
	Account       VARCHAR(4),
	Amount        decimal(18, 6) NULL,
	Fee           decimal(18, 6) NULL,
	Currency      VARCHAR(4),
    Type          VARCHAR(15),
    `Usage`       VARCHAR(10),
	CryptoAddress VARCHAR(50),
	Description   VARCHAR(1000),
	CONSTRAINT PKAccountTransaction PRIMARY KEY CLUSTERED(
		SeqNo  ASC)
);

DELIMITER //

CREATE TRIGGER InsAccountTransaction BEFORE INSERT ON AccountTransaction
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdAccountTransaction BEFORE UPDATE ON AccountTransaction
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;


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

CREATE VIEW BankTransactions
AS
SELECT
	TX.SeqNo,
	TX.Timestamp,
    TX.Completed,
    TX.TXNId,
	BK.Bank,
	BK.SortCode,
	TX.Account,
    TX.Fee,
	AC.AccountNumber,
	AC.CardNumber,
	TX.Amount,
	TX.Currency,
    TX.Type,
    TX.`Usage`,
    TX.CryptoAddress,
	TX.Description
FROM AccountTransaction TX
LEFT JOIN Account       AC
ON   TX.Account       = AC.Code
LEFT JOIN Bank          BK
ON   AC.Bank          = BK.Code;

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

