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
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ListValues',          @mode = @mode, @batch = @batch
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
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Company',             @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargerLocation',     @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargerUnit  ',       @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargeSession',       @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargeSessionLog',    @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Car',                 @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'WeeklyFuelPrices',    @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'TariffName',          @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Tariff',              @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'MeterReadingTariff',  @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'MeterReading',        @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'MeterOffPeak',        @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'Meter',               @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'SmartMeterUsageData', @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'ChargeSessionStats',  @mode = @mode, @batch = @batch
		EXEC SynchronizeTable @SQLServer, @MySQL, 'CalorificValue',      @mode = @mode, @batch = @batch
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
