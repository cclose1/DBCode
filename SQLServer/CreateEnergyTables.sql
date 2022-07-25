USE Expenditure

DROP TABLE ChargerNetwork
GO

CREATE TABLE ChargerNetwork (
	Name      VARCHAR(15)   NOT NULL,
	Modified  DATETIME      NULL,
	Phone     VARCHAR(15)   NULL,
	Web       VARCHAR(50)   NULL,
	Comment   VARCHAR(max),
	PRIMARY KEY (Name)
)
GO

CREATE TRIGGER ChargerNetworkModified ON ChargerNetwork AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CH
		SET Modified = CASE WHEN UPDATE(Modified) AND CH.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM ChargerNetwork CH
	JOIN inserted 
	ON  CH.Name  = inserted.Name
END
GO

INSERT INTO ChargerNetwork(Name, Phone, Web) VALUES ('PodPoint', '020 7247 4114', 'https://pod-point.com/')

DROP TABLE ChargerLocation
GO

CREATE TABLE ChargerLocation (
	Name      VARCHAR(20)   NOT NULL,
	Created   DATETIME      NOT NULL,
	Network   VARCHAR(15)   NULL,   -- If not null points to an entry in ChargerNetwork with Name = Network.
	Modified  DATETIME      NULL,
	Rate      DECIMAL(6,2)  NULL,
	Tariff    VARCHAR(15),
	Location  VARCHAR(15),
	Comment   VARCHAR(max),
	PRIMARY KEY (Name)
)
GO

CREATE TRIGGER ChargerLocationModified ON ChargerLocation AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CH
		SET Modified = CASE WHEN UPDATE(Modified) AND CH.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM ChargerLocation CH
	JOIN inserted 
	ON  CH.Name  = inserted.Name
END
GO

INSERT INTO ChargerLocation(Name, Created, Network, Rate, Tariff, Location) VALUES ('Anon',         '01-11-2021',  NULL,      22,  'NULL',    'NULL') 
INSERT INTO ChargerLocation(Name, Created, Network, Rate, Tariff, Location) VALUES ('Home2p3Kw',    '01-11-2021',  NULL,      2.3, 'SSEStd',  'SO22 5PJ') 
INSERT INTO ChargerLocation(Name, Created, Network, Rate, Tariff, Location) VALUES ('HomePodPoint', '01-11-2021',  'PodPoint', 7,   'SSEStd', 'SO22 5PJ')
INSERT INTO ChargerLocation(Name, Created, Network, Rate, Tariff, Location) VALUES ('PPBadgerFarm', '01-11-2021',  'PodPoint', 22,   NULL,    'SO22 4QB')

DROP TABLE ChargerUnit
GO

CREATE TABLE ChargerUnit (
	Location  VARCHAR(20)   NOT NULL, -- Points to an entry in ChargerLocation with Name = Location
	Name      VARCHAR(15)   NOT NULL,
	Modified  DATETIME      NULL,
	Active    CHAR(1),
	Comment   VARCHAR(max),
	PRIMARY KEY (Location, Name)
)
GO

CREATE TRIGGER ChargerUnitModified ON ChargerUnit AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CH
		SET Modified = CASE WHEN UPDATE(Modified) AND CH.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM ChargerUnit CH
	JOIN inserted 
	ON  CH.Location = inserted.Location
	AND CH.Name     = inserted.Name
END
GO

INSERT INTO ChargerUnit(Location, Name, Active) VALUES ('PPBadgerFarm', 'Josh-Alex A', 'N')
INSERT INTO ChargerUnit(Location, Name, Active) VALUES ('PPBadgerFarm', 'Josh-Alex B', 'N')
INSERT INTO ChargerUnit(Location, Name, Active) VALUES ('PPBadgerFarm', 'Pete-Alex A', 'Y')
INSERT INTO ChargerUnit(Location, Name, Active) VALUES ('PPBadgerFarm', 'Pete-Alex B', 'Y')

DROP TABLE ChargeSession
GO

CREATE TABLE ChargeSession (
    CarReg        VARCHAR(10)   NOT NULL,
	Start         DATETIME      NOT NULL,
	Modified      DATETIME      NULL,
	Charger       VARCHAR(20)   NULL,  -- Pointer to an entry in ChargerLocation
	Unit          VARCHAR(15)   NULL,  -- Pointer to ChargerUnit where Location = Charger and Name = Unit
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
	DefaultTariff VARCHAR(15)   NULL,
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
	Date      DATE          NOT NULL,
	Source    VARCHAR(10)   NOT NULL DEFAULT 'Dep BEIS',
	Type      VARCHAR(10)   NOT NULL DEFAULT 'Unleaded',
	Modified  DATETIME      NULL,
	PumpPrice DECIMAL(6, 2) NULL,
	Comment   VARCHAR(max),
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

INSERT INTO Car(Registration, Make, Model, Capacity, WLTP, MilesPerLitre, DefaultTariff) VALUES('EO70 ECC', 'Renault', 'Zoe',  52, 234, 8.5, 'SSEStd')
INSERT INTO Car(Registration, Make, Model, Capacity, WLTP, MilesPerLitre) VALUES('Test',     'Generic', 'Make', 50, -1,  8.5)
INSERT INTO Car(Registration, Make, Model, MilesPerLitre) VALUES('HV61 PBF',  'Suzuki', 'Splash', 8.5)
GO

DROP TABLE Tariff
GO

CREATE TABLE Tariff (
	Name           VARCHAR(15)   NOT NULL,
	Type           VARCHAR(15)   NOT NULL,
	Start          DATETIME      NOT NULL,
	[End]          DATETIME      NULL,
	Modified       DATETIME      NULL,
	UnitRate       DECIMAL(8, 3) NULL,
	StandingCharge DECIMAL(8, 3) NULL,
	Description    VARCHAR(max),
	PRIMARY KEY (Name, Type, Start)
)
GO

CREATE TRIGGER TariffModified ON Tariff AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TR
		SET Modified = CASE WHEN UPDATE(Modified) AND TR.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM Tariff TR
	JOIN inserted 
	ON  TR.Start = inserted.Start
	AND TR.Name  = inserted.Name
END
GO

INSERT INTO Tariff(Name, Type, Start, [End], UnitRate, StandingCharge) VALUES ('SSEStd', 'Electric', '01-Jan-2021', '31-Mar-2022', 19.695, 22.960)  
INSERT INTO Tariff(Name, Type, Start, [End], UnitRate, StandingCharge) VALUES ('SSEStd', 'Gas',      '01-Jan-2021', '31-Mar-2022', 3.970,  24.870)  
INSERT INTO Tariff(Name, Type, Start, [End], UnitRate, StandingCharge) VALUES ('SSEStd', 'Electric', '01-Apr-2022', NULL,          27.100, 41.320)
INSERT INTO Tariff(Name, Type, Start, [End], UnitRate, StandingCharge) VALUES ('SSEStd', 'Gas',      '01-Apr-2022', NULL,          7.123,  25.290)
