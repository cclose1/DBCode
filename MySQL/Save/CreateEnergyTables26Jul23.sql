USE Expenditure;

DROP TABLE IF EXISTS Company;

CREATE TABLE Company (
	Name      VARCHAR(15)   NOT NULL,
	Modified  DATETIME      NULL,
	Phone     VARCHAR(15)   NULL,
	Web       VARCHAR(50)   NULL,
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

TRUNCATE Company;

INSERT INTO Company
(Name, Phone, Web)
VALUES 
('Scottish Power', '0345 270 0700', 'https://www.scottishpower.co.uk/login'),
('Podpoint',       '0333 0063503',  'https://pod-point.com'),
('EB Charging',    '0330 111 0076', 'https://pod-point.com');

DROP TABLE IF EXISTS ChargerNetwork;
--
-- To be replaced by company and will be removed when code changed.
--
CREATE TABLE ChargerNetwork (
	Name      VARCHAR(15)   NOT NULL,
	Modified  DATETIME      NULL,
	Phone     VARCHAR(15)   NULL,
	Web       VARCHAR(50)   NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Name)
);

DELIMITER //

CREATE TRIGGER InsChargerNetwork BEFORE INSERT ON ChargerNetwork
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdChargerNetwork BEFORE UPDATE ON ChargerNetwork
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS ChargerLocation;

CREATE TABLE ChargerLocation (
	Name      VARCHAR(20)   NOT NULL,
	Created   DATETIME      NOT NULL,
	Network   VARCHAR(15)   NULL,   -- If not null points to an entry in ChargerNetwork with Name = Network.
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
	Location  VARCHAR(20)   NOT NULL, -- Points to an entry in ChargerLocation with Name = Location
	Name      VARCHAR(15)   NOT NULL,
	Modified  DATETIME      NULL,
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
    CarReg        VARCHAR(10)   NOT NULL,
	Start         DATETIME      NOT NULL,
	Modified      DATETIME      NULL,
	Charger       VARCHAR(20)   NULL,
	Unit          VARCHAR(15)   NULL,
	EstDuration   DECIMAL(9, 5),
	Mileage	      INT           NULL,
	StartMiles    DECIMAL(4, 1) NULL,
	StartPerCent  DECIMAL(4, 1) NULL,
	End           DATETIME      NULL,
	EndMiles      DECIMAL(4, 1) NULL,
	EndPerCent    DECIMAL(4, 1) NULL,
	Charge        DECIMAL(6, 2) NULL,
	Cost          DECIMAL(6, 2) NULL,
--	Gain          DECIMAL(6, 2) GENERATED ALWAYS AS (EndPerCent - StartPerCent) VIRTUAL,
--	Duration      DECIMAL(9, 5) GENERATED ALWAYS AS ((TIMESTAMPDIFF(SECOND, Start, End)) / 3600.0) VIRTUAL,
	Comment       VARCHAR(1000),
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

DROP TABLE IF EXISTS  Car;

CREATE TABLE Car (
    Registration  VARCHAR(10)   NOT NULL,
	Modified      DATETIME      NULL,
	Make          VARCHAR(15)   NULL,
	Model         VARCHAR(15)   NULL,
	Capacity      DECIMAL(5, 1) NULL,
	WLTP          DECIMAL(5, 1),
	MilesPerLitre DECIMAL(5, 1) NULL,
    DefaultTariff VARCHAR(15)   NULL,
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

DROP TABLE IF EXISTS EnergyRates;

CREATE TABLE EnergyRates (
	Name                   VARCHAR(15)   NOT NULL,
	Start                  DATETIME      NOT NULL,
	End                    DATETIME      NULL,
	Modified               DATETIME      NULL,
	ElectricRate           DECIMAL(8, 3) NULL,
	ElectricStandingCharge DECIMAL(8, 3) NULL,
	GasRate                DECIMAL(8, 3) NULL,
	GasStandingCharge      DECIMAL(8, 3) NULL,
	Cap                    DECIMAL(6, 2) GENERATED ALWAYS AS (29 * ElectricRate + 120 * GasRate + 3.65 * (ElectricStandingCharge + GasStandingCharge)) VIRTUAL,
	Description            VARCHAR(1000),
	PRIMARY KEY (Name, Start)
);

DELIMITER //

CREATE TRIGGER InsEnergyRates BEFORE INSERT ON EnergyRates
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

TRUNCATE EnergyRates;

INSERT INTO EnergyRates
(Name, Start, End, ElectricRate, ElectricStandingCharge, GasRate, GasStandingCharge)
VALUES 
('SSEStd', '2021-01-01 00:00:00', '2022-03-31 00:00:00', 16.103, 21.970,  2.976, 24.830),
('SSEStd', '2022-04-01 00:00:00', '2022-09-30 00:00:00', 17.935, 22.970,  3.276, 25.330),
('SSEStd', '2022-10-01 00:00:00', '2023-06-30 00:00:00', 32.596, 42.290,  9.959, 27.120),
('SSEStd', '2023-07-01 00:00:00', NULL,                  30.295, 49.590,  7.607, 29.110);

DROP TABLE IF EXISTS Tariff;

CREATE TABLE Tariff (
	Company        VARCHAR(15)   NOT NULL,
	Name           VARCHAR(15)   NOT NULL,
	Type           VARCHAR(15)   NOT NULL,
	Start          DATETIME      NOT NULL,
	End            DATETIME      NULL,
    Code           VARCHAR(15)   NOT NULL,
	Modified       DATETIME      NULL,
	UnitRate       DECIMAL(8, 3) NULL,
	StandingCharge DECIMAL(8, 3) NULL,
    CalorificValue DECIMAL(8, 3) NULL,
	Description    VARCHAR(1000),
	PRIMARY KEY (Company, Name, Type, Start)
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

CREATE UNIQUE INDEX trcode ON Tariff(Start, Type, Code);

TRUNCATE Tariff;

INSERT INTO Tariff(Company, Name, Type, Code, Start, End, UnitRate, StandingCharge, CalorificValue)
VALUES
('Scottish Power', 'Standard', 'Electric', 'SSEStd', '2021-01-01 00:00:00', '2022-03-31 23:59:59', 19.685, 22.960, NULL),
('Scottish Power', 'Standard', 'Electric', 'SSEStd', '2022-04-01 00:00:00', '2022-09-30 23:59:59', 27.100, 41.320, NULL),
('Scottish Power', 'Standard', 'Electric', 'SSEStd', '2022-10-01 00:00:00', '2022-12-31 23:59:59', 32.596, 42.290, NULL),
('Scottish Power', 'Standard', 'Electric', 'SSEStd', '2023-01-01 00:00:00', '2023-03-31 23:59:59', 32.647, 42.290, NULL),
('Scottish Power', 'Standard', 'Electric', 'SSEStd', '2023-04-01 00:00:00', '2023-06-30 23:59:59', 31.921, 47.230, NULL),
('Scottish Power', 'Standard', 'Electric', 'SSEStd', '2023-07-01 00:00:00', NULL,                  30.295, 49.590, NULL),
('Scottish Power', 'Standard', 'Gas',      'SSEStd',  '2021-01-01 00:00:00', '2022-03-31 23:59:59',  3.970, 24.870, 39.2),
('Scottish Power', 'Standard', 'Gas',      'SSEStd', '2022-04-01 00:00:00', '2022-04-30 23:59:59',  7.123, 25.920, 39.2),
('Scottish Power', 'Standard', 'Gas',      'SSEStd', '2022-05-01 00:00:00', '2022-09-30 23:59:59',  7.123, 25.920, 39.2),
('Scottish Power', 'Standard', 'Gas',      'SSEStd',  '2022-10-01 00:00:00', '2022-10-18 23:59:59',  9.959, 27.120, 39.7),
('Scottish Power', 'Standard', 'Gas',      'SSEStd',  '2022-10-19 00:00:00', '2023-03-31 23:59:59',  9.959, 27.120, 39.3),
('Scottish Power', 'Standard', 'Gas',      'SSEStd',  '2023-04-01 00:00:00', '2023-04-17 23:59:59',  9.916, 27.720, 39.1),
('Scottish Power', 'Standard', 'Gas',      'SSEStd',  '2023-04-18 00:00:00', '2023-04-21 23:59:59',  9.916, 27.720, 39.2),
('Scottish Power', 'Standard', 'Gas',      'SSEStd',  '2023-04-22 00:00:00', '2023-06-30 23:59:59',  9.916, 27.720, 39.3),
('Scottish Power', 'Standard', 'Gas',      'SSEStd',  '2023-07-01 00:00:00', NULL,                   7.607, 29.110, 39.3);

DROP TABLE IF EXISTS MeterReading;

CREATE TABLE MeterReading (
	Timestamp DATETIME       NOT NULL,
    WeekDay   VARCHAR(3)     GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
	Type      VARCHAR(15)    NOT NULL,
	Tariff    VARCHAR(15)    NOT NULL DEFAULT 'SSEStd',
	Modified  DATETIME       NULL,
	Reading   DECIMAL(10, 2) NULL,
    Estimated CHAR(1)        NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Timestamp, Type)
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