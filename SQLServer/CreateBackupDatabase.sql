
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'BackupDatabase' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.BackupDatabase
GO

CREATE PROCEDURE dbo.BackupDatabase(
					@name     SYSNAME, 
					@startDay VARCHAR(3),
					@path     VARCHAR(max) = 'C:\MyFiles\My Documents\DBBackup',
					@test     CHAR         = 'N')
AS
BEGIN	
	DECLARE @now     AS DATE         = CURRENT_TIMESTAMP
	DECLARE @start   AS DATE         = dbo.RoundDownToDay(@startDay)
	DECLARE @file    AS VARCHAR(max) = @path + '\' + @name + dbo.FormatDate(@start, 'DDMMMYY') + '.bak'
	DECLARE @setName AS VARCHAR(max) = 'Backup of ' + @name
	DECLARE @log     AS CHAR         = CASE WHEN @start = @now THEN 'N' ELSE 'Y' END
	
	IF @test = 'Y'
	BEGIN
		PRINT 'Test BackupDatabase log ' + @log + ' database ' + @name + ' file ' + @file
		RETURN
	END

	IF @start = @now
		BACKUP DATABASE @name TO DISK = @file WITH FORMAT, NAME = @setName
	ELSE
		BACKUP LOG @name TO DISK = @file WITH NOFORMAT, NOINIT, NAME = @setName
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'BackupDatabases' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.BackupDatabases
GO

CREATE PROCEDURE dbo.BackupDatabases(
					@startDay  VARCHAR(3)   = 'Sun',
					@path      VARCHAR(max) = 'C:\MyFiles\My Documents\DBBackup',
					@syncMySQL CHAR         = 'Y',
					@test      CHAR         = 'N')
AS
BEGIN
	PRINT 'Backup at ' + dbo.FormatDate(CURRENT_TIMESTAMP, 'DD-MMM-YY HH:MI:SS') 
	
	IF @syncMySQL = 'Y' EXEC BloodPressure.dbo.SynchronizeWithMySQL

	EXEC BloodPressure.dbo.BackupDatabase 'BloodPressure', @startDay, @path, @test
	EXEC BloodPressure.dbo.BackupDatabase 'Expenditure',   @startDay, @path, @test
END
GO