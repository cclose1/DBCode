IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SynchronizeNutrition' AND type ='p')
BEGIN
	DROP Procedure dbo.SynchronizeNutrition
END
GO
CREATE PROCEDURE SynchronizeNutrition(@SQLServer AS SYSNAME, @MySQL AS SYSNAME, @mode AS CHAR = 'I', @batch AS INT = null)
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionSources',   @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionTypes',     @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionDetail',    @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionEvent',     @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionRecord',    @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'NutritionComposite', @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Weight',             @mode = @mode, @batch = @batch
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
