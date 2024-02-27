USE BloodPressure

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.BMI') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.BMI
GO

CREATE FUNCTION dbo.BMI(@kilos AS DECIMAL(10,2), @height AS DECIMAL(10, 2) = 1.7)
RETURNS DECIMAL(6, 1)
AS 
BEGIN
    RETURN @kilos / SQUARE(ISNULL(@height, 1.7))
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.CalculateCalories') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.CalculateCalories
GO

CREATE FUNCTION dbo.CalculateCalories(@fat AS DECIMAL(8, 3) = NULL, @carb AS DECIMAL(8, 3), @protein AS DECIMAL(8, 3) = NULL, @units AS DECIMAL(8, 3) = NULL)
RETURNS DECIMAL(8, 3)
AS 
BEGIN
    RETURN 4 * (ISNULL(@carb, 0) + ISNULL(@protein, 0)) + 9 * ISNULL(@fat, 0) + 56 * ISNULL(@units, 0)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.WeekStart') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.WeekStart
GO

CREATE FUNCTION dbo.WeekStart(@day AS DATE)
RETURNS DATE
AS 
BEGIN
    RETURN CAST(DATEADD(D, -DATEPART(w, @day) + 1, @day) AS DATE)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.WeekDayName') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.WeekDayName
GO

CREATE FUNCTION dbo.WeekDayName(@date DATE)
RETURNS VARCHAR(3)
AS
BEGIN
    RETURN SUBSTRING(DATENAME(WeekDay, @date), 1, 3)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.GetStage') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.GetStage
GO

CREATE FUNCTION dbo.GetStage (@systolic AS INT, @diastolic AS INT, @isNICE AS CHAR)
RETURNS VARCHAR(10)
AS
BEGIN
	IF @isNICE = 'Y'
    BEGIN
		IF @systolic >= 180 OR @diastolic >= 110 RETURN '3'
		IF @systolic >= 155 OR @diastolic >= 95  RETURN '2'
		IF @systolic >= 135 OR @diastolic >= 85  RETURN '1'
		IF @systolic >= 120 OR @diastolic >= 80  RETURN 'Pre'
	END
	ELSE
	BEGIN
		IF @systolic >= 180 OR @diastolic >= 110 RETURN '3'
		IF @systolic >= 160 OR @diastolic >= 100 RETURN '2';
		IF @systolic >= 140 OR @diastolic >= 90  RETURN '1';
		IF @systolic >= 120 OR @diastolic >= 80  RETURN 'Pre'
	END
	RETURN 'Normal'
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'Append' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.Append
GO

CREATE PROCEDURE Append(@string VARCHAR(max) OUTPUT, @field VARCHAR(max), @sep VARCHAR(20))
AS
BEGIN
	SET @sep = REPLACE(REPLACE(REPLACE(@sep, '\n', CHAR(10)), '\r', CHAR(13)), '\t', CHAR(9))

	IF (@string IS NULL OR @string = '')
	BEGIN	
		SET @string = @field
	END
	ELSE
	BEGIN
		IF @sep IS NOT NULL SET @string = @string + @sep

		SET @string = @string + @field
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'Append' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.Append
GO

CREATE PROCEDURE Append(@string VARCHAR(max) OUTPUT, @field VARCHAR(max), @sep VARCHAR(20))
AS
BEGIN
	SET @sep = REPLACE(REPLACE(REPLACE(@sep, '\n', CHAR(10)), '\r', CHAR(13)), '\t', CHAR(9))

	IF (@string IS NULL OR @string = '')
	BEGIN	
		SET @string = @field
	END
	ELSE
	BEGIN
		IF @sep IS NOT NULL SET @string = @string + @sep

		SET @string = @string + @field
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'AppendClause' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.AppendClause
GO

CREATE PROCEDURE AppendClause(@string VARCHAR(max) OUTPUT, @clauseName VARCHAR(max), @clauseValue VARCHAR(max))
AS
BEGIN
	IF @clauseValue IS NULL OR @clauseValue = '' RETURN

	EXEC dbo.Append @string OUTPUT, @clauseName,  '\n'
	EXEC dbo.Append @string OUTPUT, @clauseValue, ' '
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'SelectQuery' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.SelectQuery
GO

CREATE PROCEDURE SelectQuery(
					@table    SYSNAME, 
					@fields   VARCHAR(max),
					@whereCL  VARCHAR(max),
					@groupBy  VARCHAR(max),
					@orderBy  VARCHAR(max), 
					@printSQL CHAR = NULL)
AS
BEGIN
	DECLARE @query VARCHAR(max)

	SET @query = 'SELECT'

	EXEC dbo.Append @query OUTPUT, @fields, '\n'
	EXEC dbo.AppendClause @query OUTPUT, 'FROM',     @table
	EXEC dbo.AppendClause @query OUTPUT, 'WHERE',    @whereCL
	EXEC dbo.AppendClause @query OUTPUT, 'GROUP BY', @groupBy
	EXEC dbo.AppendClause @query OUTPUT, 'ORDER BY', @orderBy

	IF @printSQL IS NOT NULL AND @printSQL = 'Y' EXEC PrintSQL @query

	BEGIN TRY
		EXEC (@query)
	END TRY


	BEGIN CATCH
		DECLARE @msg AS VARCHAR(max)
		
		SET @msg = 'SelectQuery'
		EXEC dbo.ReportError @msg
		RAISERROR ('Error reported', 16, 1)
	END CATCH	
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'AppendSelectField' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.AppendSelectField
GO

CREATE PROCEDURE AppendSelectField(
	@string VARCHAR(max) OUTPUT,
    @field  VARCHAR(max),
    @castCl VARCHAR(1000),
    @alias  VARCHAR(1000),
    @aggr   VARCHAR(20))
AS
BEGIN
	DECLARE @inField VARCHAR(1000)

    SET @inField = @field
	
	IF @aggr IS NOT NULL
	BEGIN
		SET @field = @aggr + '(' + @field + ')'
        
        IF @alias IS NULL SET @alias = @aggr + @inField
    END
    
    IF @castCl IS NOT NULL AND @castCl <> ''
	BEGIN
		SET @field = 'Cast(' + @field + ' AS ' + @castCl + ')'
        
        IF @alias IS NULL SET @alias = @inField
    END
    
	EXEC dbo.Append @string OUTPUT, @field, ',\n'
    
    IF @alias IS NOT NULL
	BEGIN
		SET @alias = ' AS ' + @alias
		EXEC dbo.Append @string OUTPUT, @alias, NULL
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'AppendGroupField' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.AppendGroupField
GO

CREATE PROCEDURE AppendGroupField(
    @field     VARCHAR(max),
	@groupBy   VARCHAR(max) OUTPUT,
	@fields    VARCHAR(max) OUTPUT,
	@orderBy   VARCHAR(max) OUTPUT,
    @direction VARCHAR(20))
AS
BEGIN
	EXEC dbo.Append @groupBy OUTPUT, @field, ','
	EXEC dbo.Append @fields  OUTPUT, @field, ',\n'
    
    IF @orderBy IS NOT NULL
	BEGIN
		EXEC dbo.Append @orderBy OUTPUT, @field, ','
        
        IF @direction IS NOT NULL AND @direction <> '' EXEC dbo.Append @orderBy OUTPUT, @direction, ' '
    END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'AddPeriodGroup' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.AddPeriodGroup
GO

CREATE PROCEDURE dbo.AddPeriodGroup(
	@period    VARCHAR(10), 
	@groupBy   VARCHAR(max) OUTPUT,
	@fields    VARCHAR(max) OUTPUT,
	@orderBy   VARCHAR(max) OUTPUT,
    @direction VARCHAR(20),
    @message   VARCHAR(100) OUTPUT)
AS
BEGIN
	SET @message = ''
    
    IF @period ='Year'
	BEGIN
		 EXEC dbo.AppendGroupField 'Year', @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, @direction
    END
	ELSE IF @period  =  'Month' 
	BEGIN
		 EXEC dbo.AppendGroupField 'Year',  @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, @direction
		 EXEC dbo.AppendGroupField 'Month', @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, @direction
    END	
	ELSE IF @period  =  'Week' 
	BEGIN
		 EXEC dbo.AppendGroupField 'Year', @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, @direction
		 EXEC dbo.AppendGroupField 'Week', @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, @direction
    END
	ELSE IF @period  =  'Date' 
	BEGIN
		 EXEC dbo.AppendGroupField 'Date', @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, @direction
	END
	ELSE
		SET @message = CONCAT('Period ', @period, ' is not valid')
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'AppendAggregateField' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.AppendAggregateField
GO

CREATE PROCEDURE dbo.AppendAggregateField(@fields VARCHAR(max) OUTPUT, @field VARCHAR(100), @aggregates VARCHAR(100))
AS
BEGIN
	DECLARE @end   INT
	DECLARE @start INT
	DECLARE @aggregate VARCHAR(13)
	DECLARE @castIndx  INT
	DECLARE @castCL    VARCHAR(1000)
	DECLARE @alias     VARCHAR(1000)    

	SET @end       = CHARINDEX('!', @aggregates)
	SET @start     = 1
	SET @aggregate = ''
	
    WHILE @end != -1
	BEGIN
        IF @end = 0
		BEGIN
            /*
             * This the final field, so extract to end of fields and set End to -1 to exit.
             */
			SET @aggregate = SUBSTRING(@aggregates, @start, LEN(@aggregates))
            SET @end       = -1
		END
		ELSE
		BEGIN
			SET @aggregate = SUBSTRING(@aggregates, @start, @end - @start)
            SET @start     = @end + 1
			SET @end       = CHARINDEX('!', @aggregates, @start)
        END
        
        SET @aggregate = Trim(@aggregate)
        SET @castIndx  = CHARINDEX(':', @aggregate)
        
        IF @castIndx = 0 
		BEGIN
			SET @castCL = NULL
		END
		ELSE
		BEGIN
			SET @castCL    = CONCAT('DECIMAL(', SUBSTRING(@aggregate, @castIndx + 1, LEN(@aggregate)), ')');
            SET @aggregate = SUBSTRING(@aggregate, 1, @castIndx - 1);
        END        
        
        IF RIGHT(@aggregate, 1) = '-'
		BEGIN
			SET @alias     = @field
            SET @aggregate = LEFT(@aggregate, LEN(@aggregate) - 1)
        END

        EXEC dbo.AppendSelectField @fields OUTPUT, @field, @castCL, @alias, @aggregate
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'AnalyseBP' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.AnalyseBP
GO

/*
 * Period specifies the aggregation period and can be Year, Month, Week or Date.
 */
CREATE PROCEDURE AnalyseBP (@period VARCHAR(10), @whereAnd VARCHAR(1000), @printSQL CHAR(1) = 'N')
AS
BEGIN
	DECLARE @fields    VARCHAR(max)
    DECLARE @groupBy   VARCHAR(1000)
    DECLARE @orderBy   VARCHAR(1000)
    DECLARE @noOrderBy VARCHAR(1000)
    DECLARE @whereCl   VARCHAR(1000)
    DECLARE @message   VARCHAR(1000)
    
	SET @orderBy   = ''
	SET @noOrderBy = NULL
	SET @whereCl   = 'Orientation IS NULL'
	SET @message   = ''

    IF @whereAnd IS NOT NULL AND @whereAnd <> '' SET @whereCl = CONCAT(@whereCl, ' AND ', @whereAnd)
    
    EXEC AppendGroupField 'Individual', @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, NULL
    EXEC AddPeriodGroup @period,  @groupBy OUTPUT, @fields OUTPUT, @orderBy OUTPUT, 'DESC', @message OUTPUT
    
    
	IF @message <> ''
	BEGIN
		SELECT @message
		RETURN
	END

	EXEC AppendGroupField 'Side', @groupBy OUTPUT, @fields OUTPUT, @noOrderBy OUTPUT, NULL
	EXEC AppendSelectField @fields OUTPUT, 'Count(*)', NULL,    'Measures', NULL
    EXEC AppendAggregateField @fields OUTPUT, 'Systolic',  'Min!Avg:4,1!Max!Stdev:4,1'
    EXEC AppendAggregateField @fields OUTPUT, 'Diastolic', 'Min!Avg:4,1!Max!Stdev:4,1'
	EXEC SelectQuery 'BloodPressure.dbo.MeasureTry', @fields, @whereCl, @groupBy, @orderBy, @printSQL
END
GO
