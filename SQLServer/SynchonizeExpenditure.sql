IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SynchronizeExpenditure' AND type ='p')
BEGIN
	DROP Procedure dbo.SynchronizeExpenditure
END
GO
CREATE PROCEDURE SynchronizeExpenditure(@SQLServer AS SYSNAME, @MySQL AS SYSNAME, @mode AS CHAR = 'I', @batch AS INT = null)
AS
BEGIN
	SET NOCOUNT ON;
	
	BEGIN TRY
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Bank',          @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'PaymentSource', @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'SpendData',     @mode = @mode, @batch = @batch, @key = 'Timestamp'
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
