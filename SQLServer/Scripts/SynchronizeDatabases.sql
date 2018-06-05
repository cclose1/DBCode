DECLARE @Base    AS VARCHAR(50) = 'MYSQL'
DECLARE @BPName  AS VARCHAR(50) = @base + 'Bp..'
DECLARE @ExpName AS VARCHAR(50) = @base + '..'
DECLARE @Batch   AS INT         = NULL

EXEC BloodPressure.dbo.SynchronizeExpenditure   'Expenditure',   @ExpName, @batch = @batch
EXEC BloodPressure.dbo.SynchronizeNutrition     'BloodPressure', @BPName,  @batch = @batch
EXEC BloodPressure.dbo.SynchronizeBloodPressure 'BloodPressure', @BPName,  @batch = @batch

EXEC BloodPressure.dbo.CompareNutrition     'BloodPressure', @BPName,  @update = 'MySQL'
EXEC BloodPressure.dbo.CompareBloodPressure 'BloodPressure', @BPName,  @update = 'MySQL'
EXEC BloodPressure.dbo.CompareExpenditure   'Expenditure',   @ExpName, @update = 'MySQL'

