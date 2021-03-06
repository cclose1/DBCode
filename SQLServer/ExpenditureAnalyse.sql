DROP FUNCTION Analyse
GO

CREATE FUNCTION Analyse(@adjustDay AS INT, @adjustAmount AS SMALLMONEY)
	RETURNS @details TABLE (
				Year              INT,
				Month             INT,
				Days              INT,
				AdHocDailyRate    NUMERIC(10, 2),
				YearTotal         AS YearEssential + YearDiscretionary + YearFixed + YearHoliday,
				MonthSpend        NUMERIC(10, 2) DEFAULT 0,
				Fixed             SMALLMONEY DEFAULT 0,
				Holiday           SMALLMONEY DEFAULT 0,
				Essential         NUMERIC(10, 2) DEFAULT 0,
				Discretionary     NUMERIC(10, 2) DEFAULT 0,
				Necessary         SMALLMONEY DEFAULT 0,
				Children          SMALLMONEY DEFAULT 0,
				YearFixed         SMALLMONEY DEFAULT 0,
				YearHoliday       SMALLMONEY DEFAULT 0,
				YearNecessary     SMALLMONEY DEFAULT 0,
				YearEssential     SMALLMONEY DEFAULT 0,
				YearDiscretionary SMALLMONEY DEFAULT 0,
				YearChildren      SMALLMONEY DEFAULT 0,
				Other             SMALLMONEY DEFAULT 0,
				Target            SMALLMONEY DEFAULT 0,
				UnderSpend        SMALLMONEY DEFAULT 0)
AS
BEGIN
	DECLARE @lMonth   AS INT
	DECLARE @mSpend   AS SMALLMONEY
	DECLARE @target   AS SMALLMONEY = 20000
	DECLARE @stop     AS DATETIME   = GETDATE()
	DECLARE @maxDate  AS DATETIME   = DATEADD(D, 1, CAST(GETDATE() AS DATE))
	DECLARE @start    AS DATETIME
	DECLARE @scale    AS FLOAT
	DECLARE @adjustE  AS SMALLMONEY = 0
	DECLARE @adjustD  AS SMALLMONEY = 0
	DECLARE @adjustEr AS FLOAT      = 0
	
	IF @adjustDay IS NOT NULL
	BEGIN
		/*
		 * Set @maxDate to final day in the month. This allows us to determine if adding @adjustDay
		 * will take us into the next month.
		 *
		 * Note: The DATEDIFF gives number of months since epoch start, i.e. date 0. Incrementing this and
		 *       adding to the epoch start gives the start of the next month. Subtracting a second from this
		 *       gives the last second of the current month.
		 */
		SET @maxDate = DATEADD(S, -1, DATEADD(M, DATEDIFF(M, 0, GETDATE()) + 1, 0))
		/*
		 * If days left in month are greater than @adjustDay increment @stop by it
		 * others set @stop to final day in month.
		 */
		IF DATEDIFF(D, @stop, @maxDate) > @adjustDay 
			SET @stop = DATEADD(D, @adjustDay, @stop)
		ELSE
			SET @stop = @maxDate
	END
	
	SET @maxDate = DATEADD(D, 1, CAST(@stop AS DATE))
	/*
	 * @sart is the earliest time for which there is complete data for all categories.
	 */ 
	SELECT @start = MIN(Timestamp) FROM SpendData WHERE Category = 'Essential'
	
	SELECT 
		@adjustEr = (
			SELECT 
				SUM(Amount) 
			FROM SpendData 
			WHERE Category = 'Essential'
			AND   Timestamp >= @start) / (
			SELECT 
				SUM(Amount) 
			FROM SpendData 
			WHERE Category IN ('Essential', 'Discretionary')
			AND   Timestamp >= @start)
			
	DECLARE spend CURSOR LOCAL FAST_FORWARD 
	FOR 
	SELECT 
		Year,
		Month,
		Category,
		ISNULL(Period, 'D') AS Period,
		Max(Timestamp)      AS Latest,
		Sum(Amount)         AS Amount		
	FROM Spend WITH (NOLOCK)
	WHERE Timestamp >= @start
	AND   Timestamp           < @maxDate
	AND   ISNULL(Ignore, 'N') = 'N'
	GROUP BY Year, Month, Category, Period
	ORDER BY Year, Month, Category, Period
	
	OPEN spend
	
	WHILE 0 = 0
	BEGIN
		DECLARE @year       AS VARCHAR(100)
		DECLARE @month      AS VARCHAR(5)
		DECLARE @category   AS VARCHAR(20)
		DECLARE @latest     AS DATETIME
		DECLARE @amount     AS SMALLMONEY
		DECLARE @monthDays  AS INT
		DECLARE @day        AS INT
		DECLARE @period     AS CHAR
		DECLARE @fMonth     AS SMALLMONEY
		
		FETCH NEXT FROM spend INTO @year, @month, @category, @period, @latest, @amount

		IF @@fetch_status <> 0 BREAK
		
		IF @lMonth IS NULL OR @lMonth <> @month
		BEGIN
			DECLARE @extAmountE AS SMALLMONEY = 0
			DECLARE @extAmountD AS SMALLMONEY = 0
			DECLARE @mFixed     AS SMALLMONEY = 0
			DECLARE @eDays      AS INT
			DECLARE @dDays      AS INT
			DECLARE @eAmount    AS FLOAT
			DECLARE @dAmount    AS FLOAT
			/*
			 * For the @month of @year, get the largest timestamp and the number of days in the month. Except for 
			 * the current month, the number of days will be the number of days in the month.
			 */
			SELECT 
				@latest    = MAX(Timestamp),
				@monthDays = DAY(DATEADD(D, -1, DATEADD(M, 1, '1-' + DATENAME(M, MAX(Timestamp)) + '-' + DATENAME(YYYY, MAX(Timestamp))))),
				@day       = DAY(MAX(Timestamp))
			FROM Spend 
			WHERE Year      = @year
			AND   Month     = @month
			AND   Timestamp < @maxDate
			/*
			 * For rate calculation need to exclude fixed Discretionary and Essential as rate is for variable
			 * spend.
			 */
			SET @fMonth = 0
			
			SELECT
				@fMonth = ISNULL(SUM(Amount), 0)
			FROM Spend
			WHERE Year      = @year
			AND   Month     = @month
			AND   Timestamp < @maxDate
			AND   Category  IN ('Essential', 'Discretionary')
			AND   Period    = 'M'
			
			IF @year = DATEPART(YYYY, GETDATE()) AND @month = DATEPART(M, GETDATE())
			BEGIN
				/*
				 * This is the final month, so apply amount extension for Esssential and Discretionary categories.
				 */
				SET @extAmountD = (1- @adjustEr) * ISNULL(@adjustAmount, 0)
				SET @extAmountE = @adjustEr      * ISNULL(@adjustAmount, 0)
				SET @latest     = @stop
				SET @day        = DATEPART(D, @stop)
			END
			
			SELECT @eAmount = Amount, @eDays = Days FROM dbo.YearTotal('Essential',     @start, @latest, 'Y', @extAmountE)
			SELECT @dAmount = Amount, @dDays = Days FROM dbo.YearTotal('Discretionary', @start, @latest, 'Y', @extAmountD)
			/*
			 * Calculate month fixed amount as it does not scale and is not extended.
			 */
			SELECT 
				@mFixed = SUM(Amount) 
			FROM Spend
			WHERE Category = 'Fixed'
			AND   Year     = @year
			AND   Month    = @month
			
			INSERT @details(
				Year,  
				Month, 
				Days,
				Essential,
				Discretionary,
				Fixed,
				MonthSpend,
				YearFixed, 
				YearHoliday, 
				YearNecessary, 
				YearDiscretionary, 
				YearEssential,
				YearChildren,
				Target) 
			VALUES (
				@year, 
				@month, 
				@day,
				CASE WHEN @period <> 'M' THEN @extAmountE ELSE 0 END,
				CASE WHEN @period <> 'M' THEN @extAmountD ELSE 0 END,
				@mFixed,
				CASE WHEN @period <> 'M' THEN (@extAmountE + @extAmountD) * @monthDays / @day  ELSE 0 END + @mFixed,
				(SELECT Amount FROM dbo.YearTotal('Fixed',     NULL, @latest, 'N', 0)),  
				(SELECT Amount FROM dbo.YearTotal('Holiday',   NULL, @latest, 'N', 0)),  
				(SELECT Amount FROM dbo.YearTotal('Necessary', NULL, @latest, 'N', 0)),  
				@dAmount, 
				@eAmount,  
				(SELECT Amount FROM dbo.YearTotal('Children',  NULL, @latest, 'N', 0)),
				@target)
			/*
			 * Calculate underspend as the amount of additional spend in Essential and Discretionary
			 * spending to bring YearTotal to Target.
			 *
			 * Note: When we have a complete years worth of data for all categories, the under spend
			 *       will be Target - YearTotal.
			 */
			UPDATE @details
				SET UnderSpend = (Target - YearTotal) * (@adjustEr * @eDays + (1 - @adjustEr) * @dDays) / 365
			SET @lMonth = @month
			SET @mSpend = 0		
		END
		/*
		 * @scale is used to scale the data for the current month to a full month and is only applied
		 * to categories Essential and Discretionary.
		 */
		IF @period <> 'M' SET @scale = 1.0 * @monthDays / @day ELSE SET @scale = 1
		/*
		 * Scale @amount for MonthSpend for categories Essential and Discretionary, as these occur at a 
		 * similar rate through month, to estimate total month spend.
		 *
		 * Don't scale for other categories, e.g. fixed spend normally takes place at start of month and scaling
		 * would give a misleadingly high value.
		 */
		IF @category = 'Children'
			UPDATE @details 
				SET Children   += @amount,
					MonthSpend += @amount
			WHERE Year  = @year
			AND   Month = @month
		ELSE IF @category = 'Necessary'
			UPDATE @details 
				SET Necessary  += @amount,
					MonthSpend += @amount
			WHERE Year  = @year
			AND   Month = @month
		ELSE IF @category = 'Fixed'
			IgnoreFixed:
			-- Already set up so execute a null statement.
		ELSE IF @category = 'Holiday'
			UPDATE @details 
				SET Holiday    += @amount,
					MonthSpend += @amount
			WHERE Year  = @year
			AND   Month = @month
		ELSE IF @category = 'Essential'
			UPDATE @details 
				SET Essential  += @amount,
					MonthSpend += @amount * @scale
			WHERE Year  = @year
			AND   Month = @month
		ELSE IF @category = 'Discretionary'
			UPDATE @details 
				SET Discretionary += @amount,
					MonthSpend    += @amount * @scale
			WHERE Year  = @year
			AND   Month = @month
		ELSE
			UPDATE @details 
				SET Other += @amount
			WHERE Year  = @year
			AND   Month = @month
		/*
		 * Recalculate for adhoc daily rate, which is average for the month for the none fixed essential and discretionary spend.
		 */
		IF @category IN ('Essential', 'Discretionary')
			UPDATE @details
				SET AdhocDailyRate = (Essential + Discretionary - @fMonth) / Days
			WHERE Year  = @year
			AND   Month = @month
			
	END
	RETURN
END
