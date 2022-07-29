USE Expenditure

DROP TABLE ChargeSession
GO

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
	[End]         DATETIME      NULL,
	EndMiles      DECIMAL(4, 1) NULL,
	EndPerCent    DECIMAL(4, 1) NULL,
	Charge        DECIMAL(6, 2) NULL,
	Cost          DECIMAL(6, 2) NULL,
--  The following calculated fields caused an error in the mysql jdbc driver 8.0.29. Earlier versions don't seem to have the problem.
--  Will look into this further and if they are needed put them in a view, which may be better anyway.
--
--	Gain          AS EndPerCent - StartPerCent,
--	Duration      AS CAST(DATEDIFF(ss, Start, [End])/3600.0 AS DECIMAL(9, 5)),
	Comment       VARCHAR(max),
	PRIMARY KEY (CarReg ASC, Start ASC)
)
GO
CREATE TRIGGER ChargeSessionModified ON ChargeSession AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CS
		SET Modified = CASE WHEN UPDATE(Modified) AND CS.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM ChargeSession CS
	JOIN inserted 
	ON  CS.CarReg = inserted.CarReg
	AND CS.Start  = inserted.Start
END
GO

DROP TABLE Car
GO

CREATE TABLE Car (
    Registration  VARCHAR(10)   NOT NULL,
	Modified      DATETIME      NULL,
	Make          VARCHAR(15)   NULL,
	Model         VARCHAR(15)   NULL,
	Capacity      DECIMAL(5, 1) NULL,
	WLTP          DECIMAL(5, 1),
	MilesPerLitre DECIMAL(5, 1) NULL,
	Comment       VARCHAR(max),
	PRIMARY KEY (Registration ASC)
)
GO

CREATE TRIGGER CarModified ON Car AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CR
		SET Modified = CASE WHEN UPDATE(Modified) AND CR.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM Car CR
	JOIN inserted 
	ON  CR.Registration = inserted.Registration
END
GO

DROP TABLE WeeklyFuelPrices
GO

CREATE TABLE WeeklyFuelPrices (
	Date          DATETIME      NOT NULL,
	Source        VARCHAR(10)   NOT NULL DEFAULT 'Dep BEIS',
	Type          VARCHAR(10)   NOT NULL DEFAULT 'Unleaded',
	Modified      DATETIME      NULL,
	PumpPrice     DECIMAL(6, 2) NULL,
	MilesPerLitre DECIMAL(5, 1) NULL,
	Comment       VARCHAR(max),
	PRIMARY KEY (Date ASC, Source, Type)
)
GO

CREATE TRIGGER WeeklyFuelPricesModified ON WeeklyFuelPrices AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE WF
		SET Modified = CASE WHEN UPDATE(Modified) AND WF.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM WeeklyFuelPrices WF
	JOIN inserted 
	ON  WF.Date   = inserted.Date
	AND WF.Source = inserted.Source
	AND WF.Type   = inserted.Type
END
GO

INSERT INTO Car(Registration, Make, Model, Capacity, WLTP, MilesPerLitre) VALUES('EO70 ECC', 'Renault', 'Zoe',  52, 234, 8.5)
INSERT INTO Car(Registration, Make, Model, Capacity, WLTP, MilesPerLitre) VALUES('Test',     'Generic', 'Make', 50, -1,  8.5)
INSERT INTO Car(Registration, Make, Model, MilesPerLitre) VALUES('HV61 PBF',  'Suzuki', 'Splash', 8.5)
GO
USE [Expenditure]
GO


INSERT INTO ChargeSession(CarReg, Start, Source, Mileage, StartMiles, StartPerCent) VALUES('EO70 ECC', '01-Jan-2021 15:00', 'Home2p5Kw', 1130, 20, 10)
GO

UPDATE ChargeSession SET [End] = '01-Jan-2021 17:30', Charge = 25, Cost = 10.5, EndMiles = 40, EndPerCent = 90 WHERE CarReg = 'EO70 ECC' AND Start = '01-Jan-2021 15:00'
GO

INSERT INTO ChargeSession(CarReg, Start, Source, Mileage, StartMiles, StartPerCent) VALUES('EO70 ECC', '03-Jan-2021 15:30', 'HomePodPoint', 1500, 25, 16)
GO

UPDATE ChargeSession SET [End] = '03-Jan-2021 15:30', Charge = 35, Cost = 11.5, EndMiles = 70, EndPerCent = 90 WHERE CarReg = 'EO70 ECC' AND Start = '03-Jan-2021 15:30'
GO

DROP TABLE Charger
GO

CREATE TABLE Charger (
	Name          VARCHAR(15)   NOT NULL,
	Start         DATETIME      NOT NULL,
	[End]         DATETIME      NULL,
	Modified      DATETIME      NULL,
	Rate          DECIMAL(6,2)  NULL,
	Tariff        VARCHAR(15),
	Location      VARCHAR(15),
	Description   VARCHAR(max),
	PRIMARY KEY (Name, Start)
)
GO

CREATE TRIGGER ChargerModified ON Charger AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CH
		SET Modified = CASE WHEN UPDATE(Modified) AND CH.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM Charger CH
	JOIN inserted 
	ON  CH.Start = inserted.Start
	AND CH.Name  = inserted.Name
END
GO

INSERT INTO Charger(Name, Start, Rate, Tariff, Location) VALUES ('Home2p3Kw',    '3-Nov-2021', 2.3, 'SSEStd', 'SO22 5PJ') 
INSERT INTO Charger(Name, Start, Rate, Tariff, Location) VALUES ('HomePodPoint', '8-Nov-2021', 7,   'SSEStd', 'SO22 5PJ')

DROP TABLE Tariff
GO

CREATE TABLE Tariff (
	Name          VARCHAR(15)   NOT NULL,
	Start         DATETIME      NOT NULL,
	[End]         DATETIME      NULL,
	Modified      DATETIME      NULL,
	CostPerkWh    DECIMAL(8, 2) NULL,
	Description   VARCHAR(max),
	PRIMARY KEY (Name, Start)
)
GO

CREATE TRIGGER TariffModified ON Tariff AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TR
		SET Modified = CASE WHEN UPDATE(Modified) AND TR.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM Charger TR
	JOIN inserted 
	ON  TR.Start = inserted.Start
	AND TR.Name  = inserted.Name
END
GO

INSERT INTO Tariff(Name, Start, [End], CostPerKwh) VALUES ('SSEStd', '01-Jan-2021', '31-Mar-2022', 19.65)  
INSERT INTO Tariff(Name, Start, [End], CostPerKwh) VALUES ('SSEStd', '01-Apr-2021', '31-Mar-2022', 27.10)

DROP TABLE ChargeStats
GO

CREATE TABLE ChargeStats (
	Start         DATETIME      NOT NULL,
	[End]         DATETIME      NULL,
	Hours         DECIMAL(9, 5) NULL,
	Charge        DECIMAL(6, 2) NULL,
	Cost          DECIMAL(6, 2) NULL,
	PRIMARY KEY (Start ASC)
)
GO