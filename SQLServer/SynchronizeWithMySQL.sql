USE BloodPressure
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SynchronizeWithMySQL' AND type ='p')
BEGIN
	DROP Procedure dbo.SynchronizeWithMySQL
END
GO
CREATE PROCEDURE SynchronizeWithMySQL(
			@linkBase AS VARCHAR(50) = 'MYSQL', 
			@batch    AS INT         = NULL)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @BPName  AS VARCHAR(50) = @linkBase + 'Bp..'
	DECLARE @ExpName AS VARCHAR(50) = @linkBase + '..'

	EXEC BloodPressure.dbo.SynchronizeExpenditure   'Expenditure',   @ExpName, @batch = @batch
	EXEC BloodPressure.dbo.SynchronizeNutrition     'BloodPressure', @BPName,  @batch = @batch
	EXEC BloodPressure.dbo.SynchronizeBloodPressure 'BloodPressure', @BPName,  @batch = @batch

	EXEC BloodPressure.dbo.CompareNutrition     'BloodPressure', @BPName,  @update = 'MySQL'
	EXEC BloodPressure.dbo.CompareBloodPressure 'BloodPressure', @BPName,  @update = 'MySQL'
	EXEC BloodPressure.dbo.CompareExpenditure   'Expenditure',   @ExpName, @update = 'MySQL'
END

