USE Expenditure

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'Test' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.Test
GO

CREATE TABLE Test (
    Name       VARCHAR(10)   NOT NULL,
	Start      DATETIME      NOT NULL,
	[End]      DATETIME      NULL,
    Date       DATE          NULL,
    Time       Time          NULL,
	Modified   DATETIME      NULL,
	Dec1       DECIMAL(9, 5) NULL,
	Dec2       DECIMAL(6, 2) NOT NULL,
	Int01	   INT           NOT NULL,
	Int02	   INT           NULL,
    Real1      REAL          NULL,
    Char10     CHAR(10)      NULL,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Name ASC, Start ASC)
)
GO

CREATE TRIGGER TestModified ON Test AFTER INSERT, UPDATE
AS 
BEGIN
	SET NOCOUNT ON;

    -- Insert statements for trigger here
	UPDATE TS
		SET Modified = CASE WHEN UPDATE(Modified) AND TS.Modified IS NOT NULL THEN inserted.Modified ELSE BloodPressure.dbo.RemoveFractionalSeconds(GETDATE()) END
	FROM Test TS
	JOIN inserted 
	ON  TS.Name  = inserted.Name
END
GO