USE BloodPressure
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SynchronizeTable' AND type ='p')
BEGIN
	DROP Procedure dbo.SynchronizeTable
END
GO
CREATE PROCEDURE SynchronizeTable(
					@SQLServer AS sysname, 
					@MySQL     AS sysname, 
					@table     AS sysname, 
					@toAndFrom AS CHAR    = 'Y', 
					@mode      AS CHAR    = 'I', 
					@key       AS SYSNAME = NULL,
					@batch     AS INT     = NULL)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sql        AS NVARCHAR(max)
	DECLARE @columns    AS NVARCHAR(max)
	DECLARE @allowIdent AS CHAR
	
	CREATE TABLE #TableDetails (
		ObjectId   INT,
		Id         INT,
		[Column]   SYSNAME,
		[Key]      CHAR,
		[Type]     SYSNAME NULL,
		Size       INT     NULL,
		Precision  INT     NULL,
		Scale      INT     NULL,
		Nullable   CHAR,
		IsIdentity CHAR,
		IsComputed CHAR)
		
	IF @toAndFrom = 'Y' SET @allowIdent = 'N' ELSE SET @allowIdent = 'Y'
	
	BEGIN TRY
	EXEC LoadTableDetails  @SQLServer, @table, @key, @allowIdentity = @allowIdent
			
	SET @SQLServer += '.dbo'
	SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
	EXEC SynchronizeTableByFields @SQLServer, @MySQL, @table, @mode, @batch
	
	IF @toAndFrom = 'Y' 
	BEGIN
		SET TRANSACTION ISOLATION LEVEL READ COMMITTED
		EXEC SynchronizeTableByFields @MySQL, @SQLServer, @table, @mode, @batch
	END
	END TRY
	BEGIN CATCH
		DECLARE @msg AS VARCHAR(max)
		
		SET @msg = 'On table ' + @table
		EXEC ReportError @msg
		RAISERROR ('Error reported', 16, 1);
	END CATCH
END
