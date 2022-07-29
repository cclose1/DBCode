USE BloodPressure
GO
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
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Currency',            @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'CurrencyRate',        @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Bank',                @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'BankTransactionType', @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'AccountUsage',        @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Account',             @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'PaymentSource',       @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'SpendData',           @mode = @mode, @batch = @batch, @key = 'Timestamp'
		EXEC SynchronizeTable @SQLServer, @MySQL, 'TransactionHeader',   @mode = @mode, @batch = @batch, @key = 'TxnKey'
		EXEC SynchronizeTable @SQLServer, @MySQL, 'TransactionLine',     @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Reminder',            @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargerNetwork',      @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargerLocation',     @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargerUnit  ',       @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargeSession',       @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Car',                 @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'WeeklyFuelPrices',    @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Tariff',              @mode = @mode, @batch = @batch
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
