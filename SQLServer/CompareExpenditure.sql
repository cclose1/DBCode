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
		EXEC CompareTable @SQLServer, @MySQL, 'ListValues',          @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Currency',            @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'CurrencyRate',        @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Bank',                @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'BankTransactionType', @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'AccountUsAGE',        @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Account',             @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'PaymentSource',       @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'SpendData',           @update = @update, @key = 'Timestamp'
		EXEC CompareTable @SQLServer, @MySQL, 'TransactionHeader',   @update = @update, @key = 'TxnKey'
		EXEC CompareTable @SQLServer, @MySQL, 'TransactionLine',     @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Reminder',            @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Company',             @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'ChargerLocation',     @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'ChargerUnit',         @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'ChargeSession',       @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Car',                 @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'WeeklyFuelPrices',    @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'TariffName',          @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Tariff',              @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'Meter',               @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'MeterReading',        @update = @update
		EXEC CompareTable @SQLServer, @MySQL, 'MeterReadingTariff',  @update = @update
	END TRY
	BEGIN CATCH
		EXEC ReportError
	END CATCH
 END
