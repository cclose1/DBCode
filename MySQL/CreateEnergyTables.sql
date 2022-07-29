USE Expenditure;

DROP TABLE IF EXISTS ChargerNetwork;

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
	Location  VARCHAR(15),
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

DROP TABLE IF EXISTS Tariff;

CREATE TABLE Tariff (
	Name           VARCHAR(15)   NOT NULL,
	Type           VARCHAR(15)   NOT NULL,
	Start          DATETIME      NOT NULL,
	End            DATETIME      NULL,
	Modified       DATETIME      NULL,
	UnitRate       DECIMAL(8, 3) NULL,
	StandingCharge DECIMAL(8, 3) NULL,
	Description    VARCHAR(1000),
	PRIMARY KEY (Name, Type, Start)
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

DROP VIEW IF EXISTS WeeklyFuel;

CREATE VIEW WeeklyFuel AS
SELECT 
	J1.Date AS Start, 
	J2.Date AS End, 
	J1.PumpPrice 
FROM (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date) Num, 
	    Date,
		PumpPrice
    FROM Expenditure.WeeklyFuelPrices) J1
LEFT OUTER JOIN (
	SELECT 
		ROW_NUMBER ( ) OVER (ORDER BY Date ) Num, 
		Date
	FROM Expenditure.WeeklyFuelPrices) J2
ON J2.Num = J1.Num + 1;