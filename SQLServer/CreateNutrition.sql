DROP TABLE NutritionSources
GO
CREATE TABLE NutritionSources(
	Name     VARCHAR(50) NOT NULL PRIMARY KEY,
	Created  DATETIME DEFAULT dbo.RemoveFractionalSeconds(GETDATE())
)
GO
DROP TABLE NutritionTypes
GO
CREATE TABLE NutritionTypes(
	Name     VARCHAR(50) NOT NULL PRIMARY KEY,
	Created  DATETIME DEFAULT dbo.RemoveFractionalSeconds(GETDATE())
)
GO
DROP TABLE NutritionDetail
GO
CREATE TABLE NutritionDetail(
	Item         VARCHAR(50) NOT NULL,
	Source       VARCHAR(50) NOT NULL,
	Start        DATETIME    NOT NULL DEFAULT GETDATE(),
	Type         VARCHAR(50),
	[End]        DATETIME DEFAULT '01-Jan-3000',
	Modified     DATETIME,
	Comment      VARCHAR(max),
	Calories     DECIMAL(6, 2),
	Protein      DECIMAL(6, 3),
	Fat          DECIMAL(6, 3),
	Saturated    DECIMAL(6, 3),
	Carbohydrate DECIMAL(6, 3),
	Sugar        DECIMAL(6, 3),
	Fibre        DECIMAL(6, 3),
	Cholesterol  DECIMAL(4, 2),
	Salt         DECIMAL(6, 3),
	DefaultSize  DECIMAL(6, 2),
	ABV          DECIMAL(4, 1),
	Simple       CHAR(1),
	IsVolume     CHAR(1),
	PackSize     DECIMAL(6, 1)
	CONSTRAINT PKNutritionRecord PRIMARY KEY CLUSTERED(
		Item   ASC,
		Source ASC,
		Start  ASC)
)
GO

CREATE TRIGGER NutritionDetailModified
   ON  NutritionDetail
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE ND
		SET Modified = CASE WHEN UPDATE(Modified) AND ND.Modified IS NOT NULL THEN inserted.Modified ELSE dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM NutritionDetail ND
	JOIN inserted 
	ON  ND.Item   = inserted.Item
	AND ND.Source = inserted.Source
	AND ND.Start  = inserted.Start
END
GO
DROP TABLE NutritionEvent
GO
CREATE TABLE NutritionEvent (
	Timestamp   DATETIME NOT NULL PRIMARY KEY,
	Modified    DATETIME NULL,
	Year        AS DATEPART(YYYY, Timestamp),
	Month       AS DATEPART(M,    Timestamp),
	Day         AS DATEPART(D,    Timestamp),
	Week        AS DATEPART(WEEK, Timestamp),
	Weekday     AS SUBSTRING(DATENAME(WEEKDAY,Timestamp),(1),(3)),
	Description VARCHAR(100),
	Comment     VARCHAR(MAX))
GO
CREATE TRIGGER NutritionEventModified
   ON  NutritionEvent
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE NE
		SET Modified = CASE WHEN UPDATE(Modified) AND NE.Modified IS NOT NULL THEN inserted.Modified ELSE dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM NutritionEvent NE
	JOIN inserted 
	ON NE.Timestamp = inserted.Timestamp
END
GO
DROP TABLE NutritionRecord
GO
CREATE TABLE NutritionRecord (
	Timestamp   DATETIME    NOT NULL,
	Item        VARCHAR(50) NOT NULL,
	Source      VARCHAR(50) NOT NULL,
	Modified    DATETIME    NULL,
	Quantity    DECIMAL(12, 2),
	ABV         DECIMAL(4, 1),
	IsComposite CHAR(1),
	CONSTRAINT PKNutritionRecord PRIMARY KEY CLUSTERED(
		Timestamp ASC,
		Item      ASC,
		Source    ASC)
)
GO
/*
 Suggested by Query Analyzer when query NutritionEventSummary was taking a long time.

CREATE NONCLUSTERED INDEX NRItmSrcTS ON NutritionRecord (
	Item      ASC,
	Source    ASC,
	Timestamp ASC
)
INCLUDE (
	Quantity,
	ABV,
	IsComposite) WITH (
		PAD_INDEX              = OFF, 
		STATISTICS_NORECOMPUTE = OFF, 
		SORT_IN_TEMPDB         = OFF, 
		DROP_EXISTING          = OFF, 
		ONLINE                 = OFF, 
		ALLOW_ROW_LOCKS        = ON, 
		ALLOW_PAGE_LOCKS       = ON) ON [PRIMARY]
GO
*/
CREATE TRIGGER NutritionRecordModified
   ON  NutritionRecord
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE NR
		SET Modified = CASE WHEN UPDATE(Modified) AND NR.Modified IS NOT NULL THEN inserted.Modified ELSE dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM NutritionRecord NR
	JOIN inserted 
	ON  NR.Timestamp = inserted.Timestamp
	AND NR.Item      = inserted.Item
	AND NR.Source    = inserted.Source
END
GO
DROP TABLE NutritionHistorical
GO
CREATE TABLE NutritionHistorical (
	Timestamp    DATETIME NOT NULL PRIMARY KEY,
	Year         AS DATEPART(YYYY, Timestamp),
	Month        AS DATEPART(M,    Timestamp),
	Day          AS DATEPART(D,    Timestamp),
	Week         AS DATEPART(WEEK, Timestamp),
	Weekday      AS SUBSTRING(DATENAME(WEEKDAY,Timestamp),(1),(3)),
	Weight       DECIMAL(12, 2),
	Description  VARCHAR(50),
	Calories     DECIMAL(12, 3),
	Protein      DECIMAL(12, 3),
	Fat          DECIMAL(12, 3),
	Saturated    DECIMAL(12, 3),
	Carbohydrate DECIMAL(12, 3),
	Sugar        DECIMAL(12, 3),
	Fibre        DECIMAL(12, 3),
	Cholesterol  DECIMAL(12, 3),
	Salt         DECIMAL(12, 3),
	Units        DECIMAL(12, 3)
)
DROP TABLE Weight
GO
CREATE TABLE Weight (
	Date  DATE NOT NULL Primary Key,
	Time  TIME,
	Kilos NUMERIC(10, 2)) 
GO

DROP TABLE TempNutrition
GO

CREATE TABLE TempNutrition (
	Item            VARCHAR(50) NOT NULL,
	Source          VARCHAR(50) DEFAULT 'Generic',
	Type            VARCHAR(50),
	Quantity        INTEGER,
	ABV             DECIMAL(12, 2),
	Calories        DECIMAL(12, 3),
	Protein         DECIMAL(12, 3),
	Fat             DECIMAL(12, 3),
	[Saturated Fat] DECIMAL(12, 3),
	Carbohydrate    DECIMAL(12, 3),
	Sugar           DECIMAL(12, 3),
	Fibre           DECIMAL(12, 3),
	Cholesterol     DECIMAL(12, 3),
	Salt            DECIMAL(12, 3),
	[G/Pack]        VARCHAR(20),
	Description     VARCHAR(50),
	DefaultSize     INTEGER,
	Simple          CHAR(1),
	CONSTRAINT PKTempNutrition PRIMARY KEY(
		Item,
		Source)
)

DROP TABLE NutritionComposite
GO
CREATE TABLE NutritionComposite(
	Item          VARCHAR(50) NOT NULL,
	Source        VARCHAR(50) NOT NULL,
	Start         DATETIME    NOT NULL DEFAULT GETDATE(),
	Type          VARCHAR(50),
	[End]         DATETIME DEFAULT '01-Jan-3000',
	Modified      DATETIME,
	Record        DATETIME,
	CONSTRAINT PKNutritionComposite PRIMARY KEY CLUSTERED(
		Item   ASC,
		Source ASC,
		Start  ASC)
)
GO
CREATE TRIGGER NutritionCompositeModified
   ON  NutritionComposite
   AFTER INSERT,UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE ND
		SET Modified = CASE WHEN UPDATE(Modified) AND ND.Modified IS NOT NULL THEN inserted.Modified ELSE dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM NutritionComposite ND
	JOIN inserted 
	ON  ND.Item   = inserted.Item
	AND ND.Source = inserted.Source
	AND ND.Start  = inserted.Start
END
GO