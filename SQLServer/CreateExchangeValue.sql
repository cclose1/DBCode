USE Expenditure


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetExchangedAmount' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION dbo.GetExchangedAmount
GO

CREATE FUNCTION dbo.GetExchangedAmount(@source varchar(10), @target varchar(10), @amount DECIMAL(20, 13))
   RETURNS DECIMAL(20, 13)
AS
BEGIN
	DECLARE @scale   AS FLOAT  = 1
	DECLARE @rate    AS DECIMAL(12, 4)
	
	IF @source = @target RETURN @amount

	IF @source = 'mBTC'
	BEGIN
		SET @scale = 0.001
		SET @source = 'BTC'
	END
	ELSE IF @target = 'mBTC'
	BEGIN
		SET @scale  = 1000
		SET @target = 'BTC'
	END

	SELECT TOP 1 
		@rate = Rate 
	FROM Expenditure.dbo.CurrencyRate 
	WHERE Source = @source 
	AND   Target = @target
	AND   CURRENT_TIMESTAMP >= Created 
	ORDER BY Created DESC

	IF @rate IS NULL
	BEGIN
		SELECT TOP 1 
			@rate = 1/Rate 
		FROM Expenditure.dbo.CurrencyRate 
		WHERE Source = @target 
		AND   Target = @source
		AND    CURRENT_TIMESTAMP >= Created 
		ORDER BY Created DESC
	END

	IF @rate IS NULL	RETURN NULL

	RETURN @scale * @amount * @rate
END
GO
