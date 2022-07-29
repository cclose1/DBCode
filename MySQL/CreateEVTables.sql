USE Expenditure;

DROP TABLE IF EXISTS  ChargeSession;

CREATE TABLE ChargeSession (
    CarReg        VARCHAR(10)   NOT NULL,
	Start         DATETIME      NOT NULL,
	Modified      DATETIME      NULL,
	Source        VARCHAR(15),
	Location      VARCHAR(15)   DEFAULT 'SO22 5PJ',
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
	Date          DATETIME      NOT NULL,
	Source        VARCHAR(10)   NOT NULL DEFAULT 'Dep BEIS',
	Type          VARCHAR(10)   NOT NULL DEFAULT 'Unleaded',
	Modified      DATETIME      NULL,
	PumpPrice     DECIMAL(6, 2) NULL,
	MilesPerLitre DECIMAL(5, 1) NULL,
	Comment       VARCHAR(1000),
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

INSERT INTO Car(Registration, Make, Model, Capacity, WLTP, MilesPerLitre) VALUES('EO70 ECC', 'Renault', 'Zoe',  52, 234, 8.5);
INSERT INTO Car(Registration, Make, Model, Capacity, WLTP, MilesPerLitre) VALUES('Test',     'Generic', 'Make', 50, -1,  8.5);
INSERT INTO Car(Registration, Make, Model, MilesPerLitre) VALUES('HV61 PBF',  'Suzuki', 'Splash', 8.5);

INSERT INTO ChargeSession(CarReg, Start, Source, Mileage, StartMiles, StartPerCent) VALUES('EO70 ECC', '2021-01-01 15:00', 'Home2p5Kw', 1130, 20, 10);
UPDATE ChargeSession SET End = '2021-01-01 17:30', Charge = 25, Cost = 10.5, EndMiles = 40, EndPerCent = 90 WHERE CarReg = 'EO70 ECC' AND Start = '2021-01-01 15:00';
INSERT INTO ChargeSession(CarReg, Start, Source, Mileage, StartMiles, StartPerCent) VALUES('EO70 ECC', '2021-01-03 15:30', 'HomePodPoint', 1500, 25, 16);

UPDATE ChargeSession SET End = '2021-01-01 15:30', Charge = 35, Cost = 11.5, EndMiles = 70, EndPerCent = 90 WHERE CarReg = 'EO70 ECC' AND Start = '2021-01-03 15:30';

DROP TABLE IF EXISTS Charger;

CREATE TABLE Charger (
	Name          VARCHAR(15)   NOT NULL,
	Start         DATETIME      NOT NULL,
	End           DATETIME      NULL,
	Modified      DATETIME      NULL,
	Rate          DECIMAL(6,2)  NULL,
	CostPerKwh    DECIMAL(6, 2),
	Location      VARCHAR(15),
	Description   VARCHAR(1000),
	PRIMARY KEY (Name, Start)
);

DELIMITER //

CREATE TRIGGER InsCharger BEFORE INSERT ON Charger
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdCharger BEFORE UPDATE ON Charger
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

INSERT INTO Charger(Name, Start, Rate, CostPerKwh, Location) VALUES ('Home2p5Kw', '2021-11-02', 2.5, 14.73, 'SO22 5PJ');
INSERT INTO Charger(Name, Start, Rate, CostPerKwh, Location) VALUES ('HomePodPoint', '2021-11-08', 7, 14.73, 'SO22 5PJ');

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