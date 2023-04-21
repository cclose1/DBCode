USE Expenditure
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'LoadLog' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.LoadLog
GO


CREATE TABLE LoadLog(
	Type       VARCHAR(50) NOT NULL,
	Reference  VARCHAR(50) NOT NULL,
	[Table]    VARCHAR(50) NOT NULL,
	Loaded     DATETIME    NULL,
	DataStart  DATETIME    NULL,
	DataEnd    DATETIME    NULL,
	Rows       INT         NULL,
	Duplicates INT         NULL,
	Errors     INT         NULL,	
	Duration   FLOAT       NULL,
	PRIMARY KEY (Type ASC, Reference ASC)
)
GO


