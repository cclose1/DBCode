USE BloodPressure
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'CompareExpenditure' AND type ='p')
BEGIN
	DROP Procedure dbo.CompareExpenditure
END
GO
CREATE PROCEDURE CompareExpenditure(@SQLServer AS sysname, @MySQL AS sysname, @update AS SYSNAME)
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		EXEC CompareTable @SQLServer, @MySQL, 'Bank',               @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Account',            @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'PaymentSource',      @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'SpendData',          @update = @update, @key = 'Timestamp'
		EXEC CompareTable @SQLServer, @MySQL, 'TransactionHeader',  @update = @update, @key = 'TxnKey'
		EXEC CompareTable @SQLServer, @MySQL, 'TransactionLine',    @update = @update
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
