IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SynchronizeNutrition' AND type ='p')
BEGIN
	DROP Procedure dbo.SynchronizeNutrition
END
GO
CREATE PROCEDURE SynchronizeNutrition(@SQLServer AS SYSNAME, @MySQL AS SYSNAME, @mode AS CHAR = 'I')
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionSources',   @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionTypes',     @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionDetail',    @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionEvent',     @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionRecord',    @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionComposite', @mode = @mode
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Weight',             @mode = @mode
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
