USE Expenditure

DROP TABLE IF EXISTS Company
GO

CREATE TABLE Company (
    Id        VARCHAR(15)   NOT NULL,
	Name      VARCHAR(15)   NOT NULL,
	Modified  DATETIME      NULL,
	Phone     VARCHAR(15)   NULL,
	Web       VARCHAR(50)   NULL,
	Credit    DECIMAL(6, 2) NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Name)
)
GO

CREATE TRIGGER CompanyModified ON Company AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CH
		SET Modified = CASE WHEN UPDATE(Modified) AND CH.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM Company CH
	JOIN inserted 
	ON  CH.Name  = inserted.Name
END

GO

-- The following index causes synchronisation to fail.
-- Don't understand why.
--
-- CREATE UNIQUE INDEX cid ON Company (Id)
-- GO

DROP TABLE IF EXISTS ChargerLocation
GO

CREATE TABLE ChargerLocation (
	Name      VARCHAR(20)   NOT NULL,
	Created   DATETIME      NOT NULL,
	Provider  VARCHAR(15)   NULL,   -- If not null points to an entry in Company with Id = Provider.
	Modified  DATETIME      NULL,
	Rate      DECIMAL(6,2)  NULL,
	Location  VARCHAR(30),
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

DROP TABLE IF EXISTS ChargerUnit
GO

CREATE TABLE ChargerUnit (
	Location  VARCHAR(20)   NOT NULL, -- Points to an entry in ChargerLocation with Name = Location
	Name      VARCHAR(15)   NOT NULL,
	Modified  DATETIME      NULL,
	Rate      DECIMAL(6,2)  NULL,
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

DROP TABLE IF EXISTS ChargeSession
GO

CREATE TABLE ChargeSession (
    CarReg         VARCHAR(10)   NOT NULL,
	Start          DATETIME      NOT NULL,
	Modified       DATETIME      NULL,
	Charger        VARCHAR(20)   NULL,  -- Pointer to an entry in ChargerLocation
	Unit           VARCHAR(15)   NULL,  -- Pointer to ChargerUnit where Location = Charger and Name = Unit
	EstDuration    DECIMAL(5, 3),
	Mileage	       INT           NULL,
	StartMiles     DECIMAL(4, 1) NULL,
	StartPerCent   DECIMAL(4, 1) NULL,
	ChargeDuration TIME          NULL,
	[End]          DATETIME      NULL,
	EndMiles       DECIMAL(4, 1) NULL,
	EndPerCent     DECIMAL(4, 1) NULL,
	Charge         DECIMAL(6, 2) NULL,
	Cost           DECIMAL(6, 2) NULL,
	Closed         Char(1)       NULL,
	Comment        VARCHAR(max),
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

DROP TABLE IF EXISTS ChargeSessionLog
GO

CREATE TABLE ChargeSessionLog (
    CarReg    VARCHAR(10)   NOT NULL,
	Timestamp DATETIME      NOT NULL,
	Session   DATETIME      NOT NULL,
	Modified  DATETIME      NULL,
	Miles     DECIMAL(4, 1) NULL,
	[Percent] DECIMAL(4, 1) NULL,
	PRIMARY KEY (CarReg ASC, Timestamp ASC)
)
GO

CREATE TRIGGER ChargeSessionLogModified ON ChargeSessionLog AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE CS
		SET Modified = CASE WHEN UPDATE(Modified) AND CS.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM ChargeSessionLog CS
	JOIN inserted 
	ON  CS.CarReg   = inserted.CarReg
	AND CS.Timestamp = inserted.Timestamp
END
GO

DROP TABLE IF EXISTS Car
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

DROP TABLE IF EXISTS WeeklyFuelPrices
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


DROP TABLE IF EXISTS TariffName
GO

CREATE TABLE TariffName (
	Company     VARCHAR(15)   NOT NULL,
	Name        VARCHAR(15)   NOT NULL,
	Code        VARCHAR(15)   NOT NULL,
	Modified    DATETIME      NULL,
	Description VARCHAR(1000),
	PRIMARY KEY (Company, Name)
)
GO

CREATE TRIGGER TariffNameModified ON TariffName AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TN
		SET Modified = CASE WHEN UPDATE(Modified) AND TN.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM TariffName TN
	JOIN inserted 
	ON  TN.Company = inserted.Company
	AND TN.Name    = inserted.Name
END
GO

CREATE UNIQUE INDEX trnamecode ON TariffName(Code)
GO

DROP TABLE IF EXISTS Tariff
GO

CREATE TABLE Tariff (
	Start          DATE          NOT NULL,
	[End]          DATE          NULL,
	Code           VARCHAR(15)   NOT NULL,
	Type           VARCHAR(15)   NOT NULL,
	Modified       DATETIME      NULL,
	UnitRate       DECIMAL(8, 3) NULL,
	OffPeakRate    DECIMAL(8, 3) NULL,
	OffPeakStart   TIME          NULL,
	OffPeakEnd     TIME          NULL,
	StandingCharge DECIMAL(8, 3) NULL,
	CalorificValue DECIMAL(8, 3) NULL,
	Comment        VARCHAR(1000),
	PRIMARY KEY (Start, Type)
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
	AND TR.Type  = inserted.Type
END
GO

DROP TABLE IF EXISTS Meter
GO

CREATE TABLE Meter (
	Identifier VARCHAR(15)    NOT NULL,
    Type       VARCHAR(15)    NOT NULL,
	Modified   DATETIME       NULL,
	Installed  DATETIME       NULL,
	Removed    DATETIME       NULL,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Identifier, Type)
)
GO

CREATE TRIGGER MeterModified ON Meter AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE MT
		SET Modified = CASE WHEN UPDATE(Modified) AND MT.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM Meter MT
	JOIN inserted 
	ON  MT.Identifier = inserted.Identifier
	AND MT.Type       = inserted.Type
END
GO

DROP TABLE IF EXISTS MeterReading
GO

CREATE TABLE MeterReading (
	Meter      VARCHAR(15)    NOT NULL,
	Timestamp  DATETIME       NOT NULL,
	Modified   DATETIME       NULL,
    WeekDay                  AS (SUBSTRING(DATENAME(weekday, Timestamp),1, 3)),
	Reading    DECIMAL(10, 2) NULL,
    OffPeakKwh DECIMAL(10, 2) NOT NULL DEFAULT 0,
    Estimated  CHAR(1)        NULL,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Meter, Timestamp)
)
GO

CREATE TRIGGER MeterReadingModified ON MeterReading AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TR
		SET Modified = CASE WHEN UPDATE(Modified) AND TR.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM MeterReading TR
	JOIN inserted 
	ON  TR.Meter     = inserted.Meter
	AND TR.Timestamp = inserted.Timestamp
END
GO

DROP TABLE IF EXISTS MeterOffPeak
GO

CREATE TABLE MeterOffPeak (
	Meter      VARCHAR(15)    NOT NULL,
	Timestamp  DATETIME       NOT NULL,
	Modified   DATETIME       NULL,
    WeekDay                   AS (SUBSTRING(DATENAME(weekday, Timestamp),1, 3)),
    Kwh        DECIMAL(10, 2) NOT NULL DEFAULT 0,
    Minutes    INT,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Meter, Timestamp)
)
GO

CREATE TRIGGER MeterOffPeakModified ON MeterOffPeak AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TR
		SET Modified = CASE WHEN UPDATE(Modified) AND TR.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM MeterReading TR
	JOIN inserted 
	ON  TR.Meter     = inserted.Meter
	AND TR.Timestamp = inserted.Timestamp
END
GO

DROP TABLE IF EXISTS MeterReadingTariff
GO

CREATE TABLE MeterReadingTariff (
	Meter     VARCHAR(15)    NOT NULL,
	Start     DATETIME       NOT NULL,
	[End]     DATETIME       NULL,
	Modified  DATETIME       NULL,
	Tariff    VARCHAR(15)    NOT NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Meter, Start)
)
GO

CREATE TRIGGER MeterReadingTariffModified ON MeterReadingTariff AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TR
		SET Modified = CASE WHEN UPDATE(Modified) AND TR.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM MeterReadingTariff TR
	JOIN inserted 
	ON  TR.Meter = inserted.Meter
	AND TR.Start = inserted.Start
END
GO


DROP TABLE IF EXISTS SmartMeterUsageData
GO

CREATE TABLE SmartMeterUsageData (
	Timestamp DATETIME       NOT NULL,
	Type      VARCHAR(15)    NOT NULL,
	Modified  DATETIME       NULL,
    Reading   DECIMAL(10, 2) NOT NULL DEFAULT 0,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Timestamp, Type)
)
GO

CREATE TRIGGER SmartMeterUsageDataModified ON SmartMeterUsageData AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE SU
		SET Modified = CASE WHEN UPDATE(Modified) AND SU.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM SmartMeterUsageData SU
	JOIN inserted 
	ON  SU.Timestamp = inserted.Timestamp
	AND SU.Type      = inserted.Type
END
GO
