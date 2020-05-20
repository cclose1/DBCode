USE Expenditure;

DROP FUNCTION IF EXISTS GetExchangedAmount;

DELIMITER $$
CREATE FUNCTION GetExchangedAmount(pSource VARCHAR(10), pTarget VARCHAR(10), amount DECIMAL(20, 13)) RETURNS decimal(20,13)
    DETERMINISTIC
BEGIN
	DECLARE scale   FLOAT;
	DECLARE vrate    FLOAT;
	
	IF pSource = pTarget THEN
		RETURN amount;
	END IF;

	IF pSource = 'mBTC' THEN
		SET scale = 0.001;
		SET pSource = 'BTC';
	ELSEIF pTarget = 'mBTC' THEN
		SET scale  = 1000;
		SET pTarget = 'BTC';
	END IF;

	SELECT 
		Rate INTO vrate
	FROM CurrencyRate 
	WHERE Source = pSource 
	AND   Target = pTarget
	AND   CURRENT_TIMESTAMP >= Created 
	ORDER BY Created DESC
    LIMIT 1;
    
	IF vrate IS NULL THEN
		SET vrate = (SELECT
			1/Rate 
		FROM CurrencyRate 
		WHERE Source = pTarget 
		AND   Target = pSource
		AND   CURRENT_TIMESTAMP >= Created 
		ORDER BY Created DESC
        LIMIT 1);
	END IF;

	IF vrate IS NULL THEN
		RETURN NULL;
	END IF;

	RETURN scale * amount * vrate;
END$$

DELIMITER ;
