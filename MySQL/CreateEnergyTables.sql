USE Expenditure;

DROP TABLE IF EXISTS Company;

CREATE TABLE Company (
    Id        VARCHAR(15)   NOT NULL,
	Name      VARCHAR(25)   NOT NULL,
	Modified  DATETIME      NULL,
	Phone     VARCHAR(15)   NULL,
	Web       VARCHAR(50)   NULL,
    Credit    DECIMAL(6, 2) NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Name)
);

DELIMITER //

CREATE TRIGGER InsCompany BEFORE INSERT ON Company
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdCompany BEFORE UPDATE ON Company
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

CREATE UNIQUE INDEX cid ON Company (Id);

TRUNCATE Company;

INSERT INTO Company
(Id, Name, Phone, Web, Comment)
VALUES 
('Cid001', 'Scottish Power', '0345 270 0700', 'https://www.scottishpower.co.uk/login', ''),
('Cid002', 'Podpoint',       '0333 0063503',  'https://pod-point.com',                 ''),
('Cid003', 'Blink Charging', '0330 111 0076', 'https://blinkcharging.co.uk/',          'Was EB Charging');

DROP TABLE IF EXISTS ChargerLocation;

CREATE TABLE ChargerLocation (
	Name      VARCHAR(25)   NOT NULL,
	Created   DATETIME      NOT NULL,
	Provider  VARCHAR(15)   NULL,   -- If not null points to an entry in Company with Id = Provider.
	Modified  DATETIME      NULL,
	Rate      DECIMAL(6,2)  NULL,
	Tariff    VARCHAR(15),
	Location  VARCHAR(30),
	Comment   VARCHAR(1000),
	PRIMARY KEY (Name)
);

DELIMITER //

CREATE TRIGGER InsChargerLocation BEFORE INSERT ON ChargerLocation
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdChargerLocation BEFORE UPDATE ON ChargerLocation
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS ChargerUnit;

CREATE TABLE ChargerUnit (
	Location  VARCHAR(25)   NOT NULL, -- Points to an entry in ChargerLocation with Name = Location
	Name      VARCHAR(25)   NOT NULL,
	Modified  DATETIME      NULL,
	Rate      DECIMAL(6,2)  NULL,	
	Active    CHAR(1),
	Comment   VARCHAR(1000),
	PRIMARY KEY (Location, Name)
);

DELIMITER //

CREATE TRIGGER InsChargerUnit BEFORE INSERT ON ChargerUnit
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdChargerUnit BEFORE UPDATE ON ChargerUnit
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS  ChargeSession;

CREATE TABLE ChargeSession (
    CarReg         VARCHAR(10)    NOT NULL,
	Start          DATETIME       NOT NULL,
	Modified       DATETIME       NULL,
	Charger        VARCHAR(25)    NULL,
	Unit           VARCHAR(25)    NULL,
	EstDuration    DECIMAL(5, 3),
	Mileage	       INT            NULL,
	StartMiles     DECIMAL(4, 1)  NULL,
	StartPerCent   DECIMAL(4, 1)  NULL,
    ChargeDuration TIME           NULL,
	End            DATETIME       NULL,
	EndMiles       DECIMAL(4, 1)  NULL,
	EndPerCent     DECIMAL(4, 1)  NULL,
	Charge         DECIMAL(6, 2)  NULL,
	Cost           DECIMAL(6, 2)  NULL,
    Closed         CHAR(1)        NULL,
	Comment        VARCHAR(1000),
	PRIMARY KEY (CarReg ASC, Start ASC)
);

DELIMITER //

CREATE TRIGGER InsChargeSession BEFORE INSERT ON ChargeSession
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdChargeSession BEFORE UPDATE ON ChargeSession
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS  ChargeSessionLog;

CREATE TABLE ChargeSessionLog (
    CarReg    VARCHAR(10)   NOT NULL,
	Timestamp DATETIME      NOT NULL,
	Session   DATETIME      NOT NULL,
	Modified  DATETIME      NULL,
	Miles     INT           NULL,
	Percent   INT           NULL,
	PRIMARY KEY (CarReg ASC, Timestamp ASC)
);

DELIMITER //

CREATE TRIGGER InsChargeSessionLog BEFORE INSERT ON ChargeSessionLog
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdChargeSessionLog BEFORE UPDATE ON ChargeSessionLog
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS  Car;

CREATE TABLE Car (
    Registration  VARCHAR(10)   NOT NULL,
	Modified      DATETIME      NULL,
	Make          VARCHAR(15)   NULL,
	Model         VARCHAR(15)   NULL,
	Capacity      DECIMAL(5, 1) NULL,
	WLTP          DECIMAL(5, 1),
	MilesPerLitre DECIMAL(5, 1) NULL,
	Comment       VARCHAR(1000),
	PRIMARY KEY (Registration ASC)
);
DELIMITER //

CREATE TRIGGER InsCar BEFORE INSERT ON Car
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdCar BEFORE UPDATE ON Car
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS WeeklyFuelPrices;

CREATE TABLE WeeklyFuelPrices (
	Date      DATE          NOT NULL,
	Source    VARCHAR(10)   NOT NULL DEFAULT 'Dep BEIS',
	Type      VARCHAR(10)   NOT NULL DEFAULT 'Unleaded',
	Modified  DATETIME      NULL,
	PumpPrice DECIMAL(6, 2) NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Date ASC, Source, Type)
);

DELIMITER //

CREATE TRIGGER InsWeeklyFuelPrices BEFORE INSERT ON WeeklyFuelPrices
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdWeeklyFuelPrices BEFORE UPDATE ON WeeklyFuelPrices
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;
DROP TABLE IF EXISTS TariffName;

CREATE TABLE TariffName (
	Company     VARCHAR(15)   NOT NULL,
	Name        VARCHAR(15)   NOT NULL,
    Code        VARCHAR(15)   NOT NULL,
	Modified    DATETIME      NULL,
	Description VARCHAR(1000),
	PRIMARY KEY (Company, Name)
);
DELIMITER //

CREATE TRIGGER InsTariffName BEFORE INSERT ON TariffName
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdTariffName BEFORE UPDATE ON TariffName
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

CREATE UNIQUE INDEX trnamecode ON TariffName( Code);

TRUNCATE TariffName;

INSERT INTO TariffName(Company, Name, Code)
VALUES
('Scottish Power', 'Standard', 'SSEStd'),
('Scottish Power', 'Test',     'SSTest');

DROP TABLE IF EXISTS CalorificValue;

CREATE TABLE CalorificValue (
	Timestamp DATETIME      NOT NULL,
	Modified  DATETIME      NOT NULL,
    Value     DECIMAL(8, 3) NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Timestamp)
);

DELIMITER //

CREATE TRIGGER InsCalorificValue BEFORE INSERT ON CalorificValue
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdCalorificValue BEFORE UPDATE ON CalorificValue
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Tariff;

CREATE TABLE Tariff (
	Start          DATETIME      NOT NULL,
	End            DATETIME      NULL,
    Code           VARCHAR(15)   NOT NULL,
	Type           VARCHAR(15)   NOT NULL,
	Modified       DATETIME      NULL,
	UnitRate       DECIMAL(8, 3) NULL,
	OffPeakRate    DECIMAL(8, 3) NULL,
    OffPeakStart   TIME,
    OffPeakEnd     TIME,
	StandingCharge DECIMAL(8, 3) NULL,
	Comment        VARCHAR(1000),
	PRIMARY KEY (Start, Type)
);

DELIMITER //

CREATE TRIGGER InsTariff BEFORE INSERT ON Tariff
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdTariff BEFORE UPDATE ON Tariff
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

TRUNCATE Tariff;

INSERT INTO Tariff(Type, Code, Start, End, UnitRate, StandingCharge, CalorificValue)
VALUES
('Electric', 'SSEStd', '2021-01-01 00:00:00', '2022-03-31 23:59:59', 19.685, 22.960, NULL),
('Electric', 'SSEStd', '2022-04-01 00:00:00', '2022-09-30 23:59:59', 27.100, 41.320, NULL),
('Electric', 'SSEStd', '2022-10-01 00:00:00', '2022-12-31 23:59:59', 32.596, 42.290, NULL),
('Electric', 'SSEStd', '2023-01-01 00:00:00', '2023-03-31 23:59:59', 32.647, 42.290, NULL),
('Electric', 'SSEStd', '2023-04-01 00:00:00', '2023-06-30 23:59:59', 31.921, 47.230, NULL),
('Electric', 'SSEStd', '2023-07-01 00:00:00', NULL,                  30.295, 49.590, NULL),
('Gas',      'SSEStd', '2021-01-01 00:00:00', '2022-03-31 23:59:59',  3.970, 24.870, 39.2),
('Gas',      'SSEStd', '2022-04-01 00:00:00', '2022-04-30 23:59:59',  7.123, 25.920, 39.2),
('Gas',      'SSEStd', '2022-05-01 00:00:00', '2022-09-30 23:59:59',  7.123, 25.920, 39.2),
('Gas',      'SSEStd', '2022-10-01 00:00:00', '2022-10-18 23:59:59',  9.959, 27.120, 39.7),
('Gas',      'SSEStd', '2022-10-19 00:00:00', '2023-03-31 23:59:59',  9.959, 27.120, 39.3),
('Gas',      'SSEStd', '2023-04-01 00:00:00', '2023-04-17 23:59:59',  9.916, 27.720, 39.1),
('Gas',      'SSEStd', '2023-04-18 00:00:00', '2023-04-21 23:59:59',  9.916, 27.720, 39.2),
('Gas',      'SSEStd', '2023-04-22 00:00:00', '2023-06-30 23:59:59',  9.916, 27.720, 39.3),
('Gas',      'SSEStd', '2023-07-01 00:00:00', NULL,                   7.607, 29.110, 39.3);

DROP TABLE IF EXISTS Meter;

CREATE TABLE Meter (
	Identifier VARCHAR(15)    NOT NULL,
	Type       VARCHAR(15)    NOT NULL,
    DeviceId   VARCHAR(30)    NULL,
	Modified   DATETIME       NULL,    
	Installed  DATETIME       NOT NULL,
    Removed    DATETIME       NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Identifier, Type)
);

DELIMITER //

CREATE TRIGGER InsMeter BEFORE INSERT ON Meter
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdMeter BEFORE UPDATE ON MeterReading
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

TRUNCATE Meter;

INSERT INTO Meter(Identifier, Type, Installed, Removed)
VALUES
('Elect1',  'Electric', '2021-11-15 14:28:00', '2023-11-17 10:00:00'),
('Gas1',    'Gas',      '2021-11-15 14:28:00', '2023-11-17 10:00:00'),
('Solar1',  'Solar',    '2021-11-15 14:28:00', NULL),
('Elect2',  'Electric', '2023-11-17 10:00:01', NULL),
('Gas2',    'Gas',      '2023-11-17 10:00:01', NULL),
('Export2', 'Export',   '2023-11-17 10:00:01', NULL);

DROP TABLE IF EXISTS MeterReading;

CREATE TABLE MeterReading (
	Meter      VARCHAR(15)    NOT NULL,
	Timestamp  DATETIME       NOT NULL,
	Modified   DATETIME       NULL,
    WeekDay    VARCHAR(3)     GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
	Reading    DECIMAL(10, 3) NULL,
    Status     VARCHAR(10)    NULL,
    Source     VARCHAR(10)    NULL,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Meter, Timestamp)
);
DELIMITER //

CREATE TRIGGER InsMeterReading BEFORE INSERT ON MeterReading
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdMeterReading BEFORE UPDATE ON MeterReading
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS MeterOffPeak;

CREATE TABLE MeterOffPeak (
	Meter      VARCHAR(15)    NOT NULL,
	Timestamp  DATETIME       NOT NULL,
	Modified   DATETIME       NULL,
    WeekDay    VARCHAR(3)     GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
    Kwh        DECIMAL(10, 3) NOT NULL DEFAULT 0,
    Minutes    INT,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Meter, Timestamp)
);
DELIMITER //

CREATE TRIGGER InsMeterOffPeak BEFORE INSERT ON MeterOffPeak
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdMeterOffPeak BEFORE UPDATE ON MeterOffPeak
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS MeterReadingTariff;

CREATE TABLE MeterReadingTariff (
	Meter     VARCHAR(15)    NOT NULL,
	Start     DATETIME       NOT NULL,
	End       DATETIME       NULL,
	Modified  DATETIME       NULL,
	Tariff    VARCHAR(15)    NOT NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Meter, Start)
);

DELIMITER //

CREATE TRIGGER InsMeterReadingTariff BEFORE INSERT ON MeterReadingTariff
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdMeterReadingTariff BEFORE UPDATE ON MeterReadingTariff
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

INSERT INTO MeterReadingTariff(Meter, Start, End, Tariff)
VALUES
('Elect1',  '2021-11-15 14:28:00', '2023-11-17 10:00:00', 'SSEStd'),
('Gas1',    '2021-11-15 14:28:00', '2023-11-17 10:00:00', 'SSEStd'),
('Elect2',  '2023-11-17 10:00:01', '2024-03-12 23:59:59', 'SSEStd'),
('Gas2',    '2023-11-17 10:00:01', '2024-03-12 23:59:59', 'SSEStd'),
('Elect2',  '2024-03-13 00:00:00', NULL, 'SSEVSv'),
('Gas2',    '2024-03-13 00:00:00', NULL, 'SSEVSv');


DROP TABLE IF EXISTS SmartMeterUsageData;

CREATE TABLE SmartMeterUsageData (
	Timestamp DATETIME       NOT NULL,
    Start     DATETIME       AS (SUBTIME(Timestamp, 3000)),
	Type      VARCHAR(15)    NOT NULL,
	Modified  DATETIME       NULL,
    WeekDay   VARCHAR(3)     GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
    Reading   DECIMAL(10, 3) NOT NULL DEFAULT 0,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Timestamp, Type)
);

DELIMITER //

CREATE TRIGGER InsSmartMeterUsageData BEFORE INSERT ON SmartMeterUsageData
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdSmartMeterUsageData BEFORE UPDATE ON SmartMeterUsageData
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS OctEnSMData;

CREATE TABLE OctEnSMData (
	Start     DATETIME       NOT NULL,
    End       DATETIME       NULL,
	Type      VARCHAR(15)    NOT NULL,
	Modified  DATETIME       NULL,
    WeekDay   VARCHAR(3)     GENERATED ALWAYS AS (SUBSTR(DAYNAME(Start), 1, 3)),
    Reading   DECIMAL(10, 3) NOT NULL DEFAULT 0,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Start, Type)
);

DELIMITER //

CREATE TRIGGER InsOctEnSMData BEFORE INSERT ON OctEnSMData
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdOctEnSMData BEFORE UPDATE ON OctEnSMData
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS ChargeSessionStats;

CREATE TABLE ChargeSessionStats (
  SessionStart    DATETIME NOT NULL,
  MeterStart      DATETIME     DEFAULT NULL,
  Kwh             DECIMAL(6,2) DEFAULT NULL,
  OpKwH           DECIMAL(6,2) DEFAULT NULL,
  OpDerivation    VARCHAR(20)  DEFAULT NULL,
  OpKwhFromCost   DECIMAL(6,2) DEFAULT NULL,
  OpKwhFromRatio  DECIMAL(6,2) DEFAULT NULL,
  OpKwhFromApprox DECIMAL(6,2) DEFAULT NULL,
  PkRate          DECIMAL(6,2) DEFAULT NULL,
  OpRate          DECIMAL(6,2) DEFAULT NULL,
  Cost            DECIMAL(6,2) DEFAULT NULL,
  PRIMARY KEY (SessionStart)
);
