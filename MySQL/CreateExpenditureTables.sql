
DROP VIEW IF EXISTS Spend;
DROP VIEW IF EXISTS SpendTransactions;
DROP VIEW IF EXISTS CurrentAccount;
DROP VIEW IF EXISTS BankTransactions;
DROP VIEW IF EXISTS DailyCurrencyRates;

DROP VIEW IF EXISTS BankTransactionsSummary;
DROP VIEW IF EXISTS MergeTransactionLines;
DROP VIEW IF EXISTS BankTransfers;

DROP TABLE IF EXISTS LoadLog;

CREATE TABLE LoadLog (
	Loaded    DATETIME      DEFAULT CURRENT_TIMESTAMP,
	DataStart DATETIME      NULL,
	DataEnd   DATETIME      NULL,
    `Table`   VARCHAR(20)   NULL,
    Reference VARCHAR(20)   NULL,
    Type      VARCHAR(20)   NULL,
    `Rows`    INT           NULL,
    Duration  DECIMAL(8, 2) NULL,
    Error     VARCHAR(1000) NULL,
	PRIMARY KEY (Loaded ASC)
);
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
	Start         DATETIME    NOT NULL,
	End           DATETIME    NULL,
	Code          VARCHAR(4)  NOT NULL,
	Bank          VARCHAR(4)  NOT NULL,
	AccountNumber VARCHAR(30) NULL,
	Type          VARCHAR(10) NOT NULL,
	CardNumber    VARCHAR(20) NULL,
	CardType      VARCHAR(20) NULL,
	Owner         VARCHAR(20) NULL,
	Description   VARCHAR(50) NULL,
	PRIMARY KEY (Start ASC, Code ASC)
); 
DROP TABLE IF EXISTS SpendData;

CREATE TABLE SpendData (
  SeqNo          int(11)       NOT NULL AUTO_INCREMENT,
  Modified       Datetime(3)   DEFAULT NULL, 
  IncurredBy     VARCHAR(20)   DEFAULT 'Chris',
  Timestamp      datetime(3)   DEFAULT NULL,
  Category       varchar(15)   DEFAULT NULL,
  Type           varchar(15)   DEFAULT NULL,
  Description    varchar(1000) DEFAULT NULL,
  Location       varchar(1000) DEFAULT NULL,
  Amount         decimal(10,2) DEFAULT NULL,
  Monthly        char(1)       DEFAULT NULL,
  `Ignore`       char(1)       DEFAULT NULL,
  Period         char(1)       DEFAULT NULL,
  Payment        varchar(10)   DEFAULT NULL,
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

DROP TABLE IF EXISTS PaymentSource;

CREATE TABLE PaymentSource(
	Code    VARCHAR(20) NOT NULL,
	Account VARCHAR(20) NULL,
	Type    VARCHAR(20) NULL,
	Comment VARCHAR(1000) NULL,
	PRIMARY KEY CLUSTERED (
		Code ASC
	)
);

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

DROP TABLE IF EXISTS  TransactionHeader;

CREATE TABLE TransactionHeader(
	SeqNo         INT              NOT NULL AUTO_INCREMENT,
	Created       DATETIME         NULL,
	Modified      DATETIME         NULL, 
	TXNId         VARCHAR(15)      NULL,	
	Description   VARCHAR(1000)    NULL,
	CONSTRAINT PKTransactionHeader PRIMARY KEY CLUSTERED(
		SeqNo  ASC)
);

ALTER TABLE TransactionHeader AUTO_INCREMENT=1000;

DELIMITER //

CREATE TRIGGER InsTransactionHeader BEFORE INSERT ON TransactionHeader
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdTransactionHeader BEFORE UPDATE ON TransactionHeader
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS TransactionLine;

CREATE TABLE TransactionLine(
    TXNId         VARCHAR(15)     NOT NULL,
    Line          INT(11)         NOT NULL,
	Modified      DATETIME        NULL, 
	Timestamp     DATETIME        NULL,
	Completed     DATETIME        NULL,
	Account       VARCHAR(4),
	Amount        decimal(20, 13) NULL,
	Fee           decimal(20, 13) NULL,
	Currency      VARCHAR(4),
    Type          VARCHAR(15),
    `Usage`       VARCHAR(10),
	CryptoAddress VARCHAR(50),
	Description   VARCHAR(1000),
	CONSTRAINT PKTransactionLine PRIMARY KEY CLUSTERED(
		TXNId  ASC,
        Line   ASC)
);

DELIMITER //

CREATE TRIGGER InsTransactionLine BEFORE INSERT ON TransactionLine
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdTransactionLine BEFORE UPDATE ON TransactionLine
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//


DROP TABLE IF EXISTS Reminder;

CREATE TABLE Reminder (
	Refid       VARCHAR(10)   NOT NULL,
	Timestamp   TIMESTAMP     NOT NULL,
	Type        VARCHAR(15)   NULL,
	Frequency   VARCHAR(1)    NULL,
	WarnDays    DECIMAL(3, 0) NULL,
	Suspended   VARCHAR(1)    NULL,
	Description VARCHAR(1000) NULL,
	Comment     VARCHAR(1000) NULL,
	PRIMARY KEY (RefId ASC) 
);
