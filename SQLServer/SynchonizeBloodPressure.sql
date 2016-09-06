USE BloodPressure
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SynchronizeBloodPressure' AND type ='p')
BEGIN
	DROP Procedure dbo.SynchronizeBloodPressure
END
GO
CREATE PROCEDURE SynchronizeBloodPressure(@SQLServer AS sysname, @MySQL AS sysname, @mode AS CHAR = 'I')
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Battery',     @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Measure',     @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'MeasureABPM', @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'DrugHistory', @mode = @mode
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END