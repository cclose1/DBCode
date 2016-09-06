DECLARE @Base    AS VARCHAR(50) = 'MYSQL'
DECLARE @BPName  AS VARCHAR(50) = @base + 'Bp..'
DECLARE @ExpName AS VARCHAR(50) = @base + '..'

EXEC BloodPressure.dbo.SynchronizeNutrition     'BloodPressure', @BPName
EXEC BloodPressure.dbo.SynchronizeBloodPressure 'BloodPressure', @BPName
EXEC BloodPressure.dbo.SynchronizeExpenditure   'Expenditure',   @ExpName

EXEC BloodPressure.dbo.CompareNutrition     'BloodPressure', @BPName,  @update = 'MySQL'
EXEC BloodPressure.dbo.CompareBloodPressure 'BloodPressure', @BPName,  @update = 'MySQL'
EXEC BloodPressure.dbo.CompareExpenditure   'Expenditure',   @ExpName, @update = 'MySQL'

