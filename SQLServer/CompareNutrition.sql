USE BloodPressure

IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'CompareNutrition' AND type ='p')
BEGIN
	DROP Procedure dbo.CompareNutrition
END
GO
CREATE PROCEDURE CompareNutrition(@SQLServer AS SYSNAME, @MySQL AS SYSNAME, @update AS SYSNAME)
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		EXEC CompareTable @SQLServer, @MySQL, 'NutritionSources',   @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'NutritionTypes',     @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'NutritionDetail',    @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'NutritionEvent',     @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'NutritionRecord',    @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'NutritionComposite', @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Weight',             @update = @update
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
