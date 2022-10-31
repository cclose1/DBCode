USE BloodPressure
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'CompareBloodPressure' AND type ='p')
BEGIN
	DROP Procedure dbo.CompareBloodPressure
END
GO
CREATE PROCEDURE CompareBloodPressure(@SQLServer AS sysname, @MySQL AS sysname, @update AS SYSNAME)
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		EXEC CompareTable @SQLServer, @MySQL, 'Battery',            @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Measure',            @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'MeasureOrientation', @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'MeasureABPM',        @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'DrugHistory',        @update = @update
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END