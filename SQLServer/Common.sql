IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.RemoveFractionalSeconds') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.RemoveFractionalSeconds
GO

CREATE FUNCTION dbo.RemoveFractionalSeconds(@timestamp AS DATETIME)
RETURNS DATETIME
AS 
BEGIN
    RETURN DATEADD(ms, -DATEPART(ms, @timestamp), @timestamp)
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.rpad') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.rpad
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.lpad') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.lpad
GO

CREATE FUNCTION dbo.lpad(
	@value    VARCHAR(max),        
	@length   INT,
	@padChar  CHAR(1))
RETURNS VARCHAR(max)
AS 
BEGIN
	IF LEN(@value) < @length
	BEGIN
		SET @padChar = ISNULL(@padChar, '0');
    
		SELECT @value = RIGHT(SUBSTRING(REPLICATE(@padChar, @length), 1, (@length + 1) - LEN(RTRIM(@value))) + RTRIM(@value), @length)
	END
    RETURN @value
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.rpad') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.rpad
GO

CREATE FUNCTION dbo.rpad(
	@value    VARCHAR(max),        
	@length   INT,
	@padChar  CHAR(1))
RETURNS VARCHAR(max)
AS 
BEGIN
	IF LEN(@value) < @length
	BEGIN
		SET @padChar = ISNULL(@padChar, '0');
    
		SELECT @value = LEFT(RTRIM(@value) + SUBSTRING(REPLICATE(@padChar, @length), 1, (@length + 1) - LEN(RTRIM(@value))), @length)
	END
    RETURN @value
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.ConvertReserved') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.ConvertReserved
GO

CREATE FUNCTION dbo.ConvertReserved(@name AS sysname)
   RETURNS sysname
AS
BEGIN
	IF @name IS NOT NULL AND @name IN ('End', 'Key', 'Function', 'Server', 'Column')
		RETURN '[' + @name + ']'
	
	RETURN @name
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.GetTimeDiff') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.GetTimeDiff
GO

CREATE FUNCTION dbo.GetTimeDiff(@start AS DATETIME, @end AS DATETIME)
   RETURNS FLOAT
AS
BEGIN
	DECLARE @seconds AS FLOAT
	
	-- First try the difference as seconds and then as milliseconds if the number of millisecond will not exceed an
	-- integer which only hold a value that is less than 32 bits.
	
	SET @seconds = CAST(DATEDIFF(S, @start, @end) AS FLOAT)
	
	IF @seconds < 2147483 SET @seconds = CAST(DATEDIFF(MS, @start, @end) / 1000.0 AS FLOAT)
	
	RETURN @seconds
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.GetDelayFormat') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.GetDelayFormat
GO

CREATE FUNCTION dbo.GetDelayFormat(@delay FLOAT)
   RETURNS VARCHAR(20)
AS
BEGIN
	DECLARE @s AS INT
	DECLARE @h AS INT
	DECLARE @m AS INT
	
	-- Set @delay to the fractional seconds
	SET @s      = FLOOR(@delay)
	SET @h      = 0
	SET @m      = 0
	SET @delay  = @delay - @s
	
	-- Get the hours
	
	IF @s > 3600
	BEGIN
		SET @h = @s / 3600
		SET @s = @s % 3600
	END

	-- Get the minutes
	
	IF @s > 60
	BEGIN		
		SET @m = @s / 60
		SET @s = @s % 60
	END
	
	RETURN REPLACE(STR(@h, 2) + ':' + STR(@m, 2) + ':' + STR(@s + @delay, 6, 3), ' ', '0')
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.CharIndexMax') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.CharIndexMax
GO

CREATE FUNCTION dbo.CharIndexMax(@text varchar(max), @char char(1), @start int, @maxLength int)
   RETURNS int
AS
BEGIN
	DECLARE @i     int
	DECLARE @index int

	SET @i     = @start - 1
	SET @index = 0

	WHILE 0 = 0
	BEGIN
		SET @i = CHARINDEX(@char, @text, @i + 1)

		IF @i <> 0 
		BEGIN
			IF @i - @start + 1 > @maxLength RETURN @index

			SET @index = @i
		END

		IF @i = 0 RETURN @index
	END

	RETURN @index
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.RoundDownTime') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.RoundDownTime
GO

CREATE FUNCTION dbo.RoundDownTime(@time AS DATETIME, @intervalSeconds AS INT)
   RETURNS DATETIME
AS
BEGIN
	DECLARE @seconds AS INT

	SET @seconds = 60 * DATEPART(MI, @time) + DATEPART(S, @time)
	
	RETURN DATEADD(S, @intervalSeconds * (@seconds / @intervalSeconds), DATEADD(S, -@seconds, @time))
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'ExtractField' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION dbo.ExtractField
GO

-- Sets Value to the string starting at @offset and terminated by any of the characters in @separators or the end of string.
--
-- The characters space, tab, cr and lf are regarded as white space and are removed from the start of field and
-- are removed from the end of the field.
--
-- @separators can contain white space characters, however, they only take effect after the first none white space.
--
-- If @remove is not NULL it should be 1 or 2 characters. If it is 1 character then it is equivalent to a 2 character string
-- with both characters equal.
--
-- If the first character of @field matches @remove(1) it is removed and if the last character of @field matches @remove(2)
-- it is removed, e.g. if @field = '[name]' then setting @remove = '[]' results in @field = 'name'.
--
-- Note: If @remove characters result in the removal of characters then remaining white space will be trimmed. However, if
--       there is a white space separator between the last character and the right remove, it terminates the field and the
--       the right remove will be at the start of the next field.
--
-- On return NextOffset points to the character following the terminating separator 
-- and Separator contains the terminating separator.

CREATE FUNCTION dbo.ExtractField(
					@fields     varchar(max),
					@offset     bigint,
					@separators varchar(100),
					@remove		char(2) = NULL)
	RETURNS @field TABLE (Value VARCHAR(max), Separator CHAR, NextOffset BIGINT)
AS
BEGIN
	DECLARE @lrem      char
	DECLARE @rrem      char
	DECLARE @last      int
	DECLARE @lastr     int
	DECLARE @findex    int
	DECLARE @value     varchar(max)
	DECLARE @separator char
	
	SET @value     = NULL
	SET @separator = NULL
	SET @findex    = 0
	SET @lrem      = ''
	SET @rrem      = ''
	
	IF LEN(@remove) > 0
	BEGIN
		SET @lrem = SUBSTRING(@remove, 1, 1)
		
		IF LEN(@remove) > 1 SET @rrem = SUBSTRING(@remove, 2, 1) ELSE SET @rrem = @rrem 
	END
	
	WHILE @offset <= LEN(@fields)
	BEGIN
		DECLARE @c  char
		DECLARE @i  int
		DECLARE @ws char

		SET @c      = SUBSTRING(@fields, @offset, 1)
		SET @offset = @offset + 1
		SET @i      = CHARINDEX(@c, @separators)

		IF @c = ' ' OR @c = CHAR(9) OR @c = CHAR(13) OR @c = CHAR(10) SET @ws = 'Y' ELSE SET @ws = 'N'

		IF @value IS NULL
		BEGIN
			-- If the character matches left remove, clear @lrem as only remove first and don't store character.

			IF @lrem = @c
				SET @lrem = NULL
				
			-- If the charecter is not white space and not a separator copy it to the field.
			
			ELSE IF @i = 0 AND @ws = 'N'
			BEGIN
				SET @last   = 1
				SET @value  = @c
				SET @findex = 1
			END
			
			-- Clear the separator index if the character is white space.

			IF @ws = 'Y' SET @i = 0
		END
		ELSE IF @i = 0
		BEGIN
			SET @value  = @value + @c
			SET @findex = @findex + 1
			
			-- If not white space or the remove charater set @last as the final none white space character
			-- and clear the saved position of the last right remove character.
			
			IF @ws = 'N' AND @c <> @rrem
			BEGIN
				-- Save the last none white space character
				SET @last  = @findex
				SET @lastr = NULL
			END
			
			-- Save the position of the last right remove character in case we get consecutive 
			-- right remove characters, ignoring spaces.
			
			IF @c = @rrem
			BEGIN
				-- If the previous none white space set it as the last none white space of the field.
				
				IF @lastr IS NOT NULL SET @last = @lastr
				
				SET @lastr = @findex
			END
		END

		IF @i <> 0
		BEGIN
			SET @separator = SUBSTRING(@separators, @i, 1)
			BREAK
		END
	END
	
	IF @value IS NOT NULL SET @value = SUBSTRING(@value, 1, @last)
	
	INSERT @field VALUES(@value, @separator, @offset)
	RETURN
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.NextField') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE dbo.NextField
GO
-- Sets @field to the string starting at @index and terminated by any of the characters in @separators or the end of string.
--
-- The characters space, tab, cr and lf are regarded as white space and are removed from the start of field and
-- are removed from the end of the field.
--
-- @separators can contain white space characters, however, they only take effect after the first none white space.
--
-- If @remove is not NULL it should be 1 or 2 characters. If it is 1 character then it is equivalent to a 2 character string
-- with both characters equal.
--
-- If the first character of @field matches @remove(1) it is removed and if the last character of @field matches @remove(2)
-- it is removed, e.g. if @field = '[name]' then setting @remove = '[]' results in @field = 'name'.
--
-- Note: If @remove characters result in the removal of characters then remaining white space will be trimmed. However, if
--       there is a white space separator between the last character and the right remove, it terminates the field and the
--       the right remove will be at the start of the next field.
--
-- On return @index points to the character following the terminating separator.
CREATE PROCEDURE dbo.NextField(
					@fields     varchar(max),
					@index      int          OUTPUT,
					@separators varchar(100),
					@field      varchar(max) OUTPUT,
                    @separator  char         OUTPUT,
					@remove		char(2) = NULL)
AS
BEGIN
	DECLARE @lrem   char
	DECLARE @rrem   char
	DECLARE @last   int
	DECLARE @lastr  int
	DECLARE @findex int
	
	SET @field     = NULL
	SET @separator = NULL
	SET @findex    = 0
	SET @lrem      = ''
	SET @rrem      = ''
	
	IF LEN(@remove) > 0
	BEGIN
		SET @lrem = SUBSTRING(@remove, 1, 1)
		
		IF LEN(@remove) > 1 SET @rrem = SUBSTRING(@remove, 2, 1) ELSE SET @rrem = @rrem 
	END
	
	WHILE @index <= LEN(@fields)
	BEGIN
		DECLARE @c  char
		DECLARE @i  int
		DECLARE @ws char

		SET @c     = SUBSTRING(@fields, @index, 1)
		SET @index = @index + 1
		SET @i     = CHARINDEX(@c, @separators)

		IF @c = ' ' OR @c = CHAR(9) OR @c = CHAR(13) OR @c = CHAR(10) SET @ws = 'Y' ELSE SET @ws = 'N'

		IF @field IS NULL
		BEGIN
			-- If the character matches left remove, clear @lrem as only remove first and don't store character.

			IF @lrem = @c
				SET @lrem = NULL
				
			-- If the charecter is not white space and not a separator copy it to the field.
			
			ELSE IF @i = 0 AND @ws = 'N'
			BEGIN
				SET @field  = @c
				SET @findex = 1
			END
			
			-- Clear the separator index if the character is white space.

			IF @ws = 'Y' SET @i = 0
		END
		ELSE IF @i = 0
		BEGIN
			SET @field  = @field + @c
			SET @findex = @findex + 1
			
			-- If not white space or the remove charater set @last as the final none white space character
			-- and clear the saved position of the last right remove character.
			
			IF @ws = 'N' AND @c <> @rrem
			BEGIN
				-- Save the last none white space character
				SET @last  = @findex
				SET @lastr = NULL
			END
			
			-- Save the position of the last right remove character in case we get consecutive 
			-- right remove characters, ignoring spaces.
			
			IF @c = @rrem
			BEGIN
				-- If the previous none white space set it as the last none white space of the field.
				
				IF @lastr IS NOT NULL SET @last = @lastr
				
				SET @lastr = @findex
			END
		END

		IF @i <> 0
		BEGIN
			SET @separator = SUBSTRING(@separators, @i, 1)
			BREAK
		END
	END
	
	IF @field IS NOT NULL SET @field = SUBSTRING(@field, 1, @last)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.GetTextId') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE dbo.GetTextId
GO

CREATE PROCEDURE dbo.GetTextId(@text  varchar(8000) OUTPUT,
					           @id    int           OUTPUT,
					           @strip char = NULL)
AS
BEGIN
	IF @strip IS NOT NULL
	BEGIN
		DECLARE @i int
		
		SET @i = CHARINDEX(@strip, @text)
		
		IF @i > 0 SET @text = SUBSTRING(@text, @i + 1, LEN(@text) - @i)
	END

	SET @id = NULL	
	SELECT @id = Id FROM CSCText WHERE Value = @text
	
	IF @id IS NULL
	BEGIN
		INSERT INTO CSCText (Value) VALUES (@text)
		SELECT @id = Id FROM CSCText WHERE Value = @text
	END
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.GetField') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.GetField
GO

CREATE FUNCTION dbo.GetField(@source varchar(max), @id varchar(100))
   RETURNS varchar(max)
AS
BEGIN
	DECLARE @start int
	DECLARE @end   int

	IF @source IS NULL RETURN NULL

	SET @start = CHARINDEX(@id + '=', @source)

	IF @start = 0 RETURN NULL
	
	SET @start = @start + LEN(@id) + 1
	SET @end   = CHARINDEX(';', @source, @start)

	IF @end = 0 SET @end = CHARINDEX(' ', @source, @start)

	IF @end = 0 SET @end = LEN(@source) + 1

	RETURN SUBSTRING(@source, @start, @end - @start)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.GetSuffix') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.GetSuffix
GO

CREATE FUNCTION dbo.GetSuffix(@field varchar(max), @separator char = '.')
   RETURNS varchar(max)
AS
BEGIN
	DECLARE @pos int
	DECLARE @i   int

	IF @field IS NULL RETURN ''

	SET @i   = 0
    SET @pos = 0

	WHILE @i = @i
	BEGIN
		SET @i = CHARINDEX(@separator, @field, @i + 1)

		IF @i = 0 BREAK

		SET @pos = @i + 1
	END

	IF @pos = 0 RETURN ''
	
	RETURN SUBSTRING(@field, @pos, LEN(@field))
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.GetPrefix') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.GetPrefix
GO

CREATE FUNCTION dbo.GetPrefix(@field varchar(max), @separator char = '.')
   RETURNS varchar(max)
AS
BEGIN
	DECLARE @pos int
	DECLARE @i   int

	IF @field IS NULL RETURN ''

	SET @i   = 0
    SET @pos = 0

	WHILE @i = @i
	BEGIN
		SET @i = CHARINDEX(@separator, @field, @i + 1)

		IF @i = 0 BREAK

		SET @pos = @i - 1
	END

	IF @pos = 0 RETURN ''
	
	RETURN SUBSTRING(@field, 1, @pos)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.FormatDate') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.FormatDate
GO

CREATE FUNCTION dbo.FormatDate(@timestamp DATETIME, @format VARCHAR(32))
	RETURNS VARCHAR(32)
AS
BEGIN
    DECLARE @formatted VARCHAR(32)

	SET @formatted = @format

	IF @timestamp IS NULL SET @timestamp = CURRENT_TIMESTAMP
	
    IF CHARINDEX('YYYY',  @formatted) > 0  SET @formatted = REPLACE(@formatted, 'YYYY', DATENAME(YY, @timestamp))
    IF CHARINDEX('YY',    @formatted) > 0  SET @formatted = REPLACE(@formatted, 'YY',   RIGHT(DATENAME(YY, @timestamp), 2))
    IF CHARINDEX('DD',    @formatted) > 0  SET @formatted = REPLACE(@formatted, 'DD',   RIGHT('0' + CONVERT(VARCHAR, DATEPART(DD, @timestamp)), 2))
    IF CHARINDEX('D',     @formatted) > 0  SET @formatted = REPLACE(@formatted, 'D',    CONVERT(VARCHAR, DATEPART(DD, @timestamp)))
    IF CHARINDEX('HH',    @formatted) > 0  SET @formatted = REPLACE(@formatted, 'HH',   RIGHT('0' + CONVERT(VARCHAR, DATEPART(HH, @timestamp)), 2))
    IF CHARINDEX('MI',    @formatted) > 0  SET @formatted = REPLACE(@formatted, 'MI',   RIGHT('0' + CONVERT(VARCHAR, DATEPART(MI, @timestamp)), 2))
    IF CHARINDEX('SS',    @formatted) > 0  SET @formatted = REPLACE(@formatted, 'SS',   RIGHT('0' + CONVERT(VARCHAR, DATEPART(SS, @timestamp)), 2))
    IF CHARINDEX('.000',  @formatted) > 0  
		SET @formatted = REPLACE(@formatted, '000',  RIGHT('0' + CONVERT(VARCHAR, DATEPART(MS, @timestamp)), 3))
    ELSE IF CHARINDEX('.00',  @formatted) > 0  
		SET @formatted = REPLACE(@formatted, '00',   RIGHT('0' + CONVERT(VARCHAR, DATEPART(MS, @timestamp)), 2))
    ELSE IF CHARINDEX('.0',  @formatted) > 0  
		SET @formatted = REPLACE(@formatted, '0',    RIGHT('0' + CONVERT(VARCHAR, DATEPART(MS, @timestamp)), 1))
    IF CHARINDEX('MMM',   @formatted) > 0  
		SET @formatted = REPLACE(@formatted, 'MMM',  LEFT(DATENAME(MM, @timestamp), 3))
    ELSE IF CHARINDEX('MM',    @formatted) > 0 
		SET @formatted = REPLACE(@formatted, 'MM',   RIGHT('0' + CONVERT(VARCHAR, DATEPART(MM, @timestamp)), 2))
    ELSE IF CHARINDEX('M',     @formatted) > 0  
		SET @formatted = REPLACE(@formatted, 'M',    CONVERT(VARCHAR, DATEPART(MM, @timestamp)))

	RETURN @formatted
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.UTLTimeDiff') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.UTLTimeDiff
GO

CREATE FUNCTION dbo.UTLTimeDiff(@from DATETIME, @to DATETIME)
	RETURNS FLOAT
BEGIN
	DECLARE @time AS FLOAT
	
	SET @time = CAST(DATEDIFF(MI, @from, @to) AS FLOAT)
	
	IF ABS(@time) > 2147483647.0 / 1000 RETURN 60 * @time
	
	SET @time = CAST(DATEDIFF(S, @from, @to) AS FLOAT)
	
	IF ABS(@time) > 2147483647.0 / 1000 RETURN @time
	
	RETURN CAST(DATEDIFF(MS, @from, @to) AS FLOAT) / 1000.0
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.ReportTimeTaken') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
	DROP PROCEDURE dbo.ReportTimeTaken
GO

CREATE PROCEDURE dbo.ReportTimeTaken(
						@message          VARCHAR(max), 
						@startTime        DATETIME OUTPUT, 
						@includeTimestamp CHAR = 'Y', 
						@includeDuration  CHAR = 'Y', 
						@includeMilliSec  CHAR = 'Y',
						@durationPlaces   INT  = 2,
						@durationWidth    INT  = 5,
						@print            CHAR = 'Y')
AS
BEGIN
	DECLARE @time     AS VARCHAR(60) = ''
	DECLARE @duration AS VARCHAR(20) = ''
	
	IF @includeTimestamp = 'Y' 
	BEGIN
		IF @includeMilliSec = 'Y'
			SET @time = dbo.FormatDate(@startTime, 'DD-MMM-YY HH:MI:SS.000 ')
		ELSE
			SET @time = dbo.FormatDate(@startTime, 'DD-MMM-YY HH:MI:SS ')
	END
	
	IF @includeDuration = 'Y'
	BEGIN
		DECLARE @elapsed AS FLOAT
		DECLARE @places  AS INT
		
		SET @elapsed = dbo.UTLTimeDiff(@startTime, CURRENT_TIMESTAMP)
		
		IF @durationPlaces IS NULL
		BEGIN
			SET @places  = 0

			IF @elapsed < 100 SET @places = 1
			IF @elapsed < 10  SET @places = 2
			IF @elapsed < 1   SET @places = 3
		END
		ELSE
			SET @places =  @durationPlaces
		
		SET @duration = LTRIM(STR(@elapsed, 15, @places))
		
		IF @durationWidth IS NOT NULL
		BEGIN
			WHILE LEN(@duration) < @durationWidth SET @duration = ' ' + @duration
		END
		
		SET @duration += ' '
	END
	
	IF @print = 'Y'
		PRINT @time + @duration + @message 
	ELSE
		SELECT @time + @duration + @message 
		
	SET @startTime = CURRENT_TIMESTAMP
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetCharIndex' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION GetCharIndex
GO

CREATE FUNCTION GetCharIndex(@value AS VARCHAR(max), @start AS INT, @match AS CHAR = ',', @quote AS CHAR = NULL)
	RETURNS INT
AS
BEGIN
	DECLARE @inQuote AS CHAR
	
	SET @inQuote = 'N'
		
	WHILE @start <= LEN(@value)
	BEGIN
		DECLARE @ch AS CHAR
		
		SET @ch = SUBSTRING(@value, @start, 1)
		
		IF @ch = @quote
		BEGIN
			IF @inQuote = 'N' SET @inQuote = 'Y' ELSE SET @inQuote = 'N'
		END
		
		IF @ch = @match AND @inQuote = 'N' RETURN @start
		
		SET @start = @start + 1
	END
	
	RETURN 0
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetSeparatorIndex' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION GetSeparatorIndex
GO

CREATE FUNCTION GetSeparatorIndex(@value AS VARCHAR(max), @start AS INT, @separator AS CHAR = ',', @quote AS CHAR = NULL)
	RETURNS INT
AS
BEGIN
	DECLARE @first AS CHAR
	DECLARE @last  AS CHAR
	
	SET @first = NULL
	SET @last  = NULL
		
	WHILE @start <= LEN(@value)
	BEGIN
		DECLARE @ch AS CHAR
				
		SET @ch = SUBSTRING(@value, @start, 1)
		
		IF @ch <> ' '
		BEGIN
			IF @ch <> @separator
			BEGIN
				IF @first IS NULL 
					SET @first = @ch 
				ELSE  
					SET @last = @ch
			END
			ELSE IF @quote IS NULL OR @first <> @quote OR @first = @quote AND @last = @quote 
				RETURN @start
		END
		
		SET @start = @start + 1
	END
	
	RETURN 0
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UnpackNameValues' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION UnpackNameValues
GO

CREATE FUNCTION UnpackNameValues(
					@list          AS VARCHAR(max), 
					@listSeparator AS CHAR = ',', 
					@pairSeparator AS CHAR = '=', 
					@quote         AS CHAR = NULL,
					@removeQuote   AS CHAR = 'Y')
	RETURNS @elements TABLE (Position INT, Name VARCHAR(max), Value VARCHAR(max), Quoted CHAR)
AS
BEGIN
	DECLARE @start   AS INT
	DECLARE @end     AS INT
	DECLARE @i       AS INT
	DECLARE @name    AS VARCHAR(max)
	DECLARE @value   AS VARCHAR(max)
	DECLARE @quoted  AS CHAR
	
	IF @list IS NULL RETURN
		
	SET @end   = -1
	SET @start = 0
	SET @i     = 0
	
	WHILE @end <> 0
	BEGIN
		SET @i   = @i + 1
		SET @end = dbo.GetSeparatorIndex(@list, @start, @pairSeparator, NULL)
		
		IF @end = 0 
			SET @name = NULL
		ELSE
		BEGIN
			SET @name  = LTRIM(RTRIM(SUBSTRING(@list, @start, @end - @start)))
			SET @start = @end + 1
		END
		
		SET @end = dbo.GetSeparatorIndex(@list, @start, @listSeparator, @quote)
		
		IF @end = 0
			SET @value  = LTRIM(RTRIM(SUBSTRING(@list, @start, LEN(@list) - @start + 1)))
		ELSE
			SET @value  = LTRIM(RTRIM(SUBSTRING(@list, @start, @end - @start)))
			
		SET @quoted = 'N'
		SET @start  = @end + 1
			
		IF @quote IS NOT NULL
		BEGIN
			IF CHARINDEX(@quote, @value) = 1 AND CHARINDEX(@quote, @value, LEN(@value)) <> 0
			BEGIN 
				SET @quoted = 'Y'
					
				IF @removeQuote = 'Y' SET @value = SUBSTRING(@value, 2, LEN(@value) - 2)
			END
		END
			
		INSERT INTO @elements VALUES (@i, @name, @value, @quoted)
	END
	
	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UnpackPairedList' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION UnpackPairedList
GO

CREATE FUNCTION UnpackPairedList(@list AS VARCHAR(max), @listSeparator AS CHAR = ',', @pairSeparator AS CHAR = '=', @quote AS CHAR = NULL)
	RETURNS @elements TABLE (Position INT, Name VARCHAR(max), Value VARCHAR(max))
AS
BEGIN
	DECLARE @start   AS INT
	DECLARE @end     AS INT
	DECLARE @element AS VARCHAR(max)
	DECLARE @i       AS INT
	DECLARE @pIndex  AS INT
	
	IF @list IS NULL RETURN
		
	SET @end   = -1
	SET @start = 0
	SET @i     = 0
	
	WHILE @end <> 0
	BEGIN
		SET @i   = @i + 1
		SET @end = dbo.GetCharIndex(@list, @start, @listSeparator, @quote)
		
		IF @end = 0 
			SET @element = SUBSTRING(@list, @start, LEN(@list) - @start + 1)
		ELSE
			SET @element = SUBSTRING(@list, @start, @end - @start)
		
		SET @start = @end + 1
		
		SET @pIndex  = CHARINDEX(@pairSeparator, @element)
		
		IF @pIndex = 0
			INSERT INTO @elements VALUES (@i, LTRIM(RTRIM(@element)), NULL)
		ELSE
			INSERT INTO @elements VALUES (@i, LTRIM(RTRIM(LEFT(@element, @pIndex - 1))), LTRIM(RTRIM(RIGHT(@element, LEN(@element)- @pIndex))))
	END
	
	RETURN
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UnpackList' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION UnpackList
GO

CREATE FUNCTION UnpackList(@list AS VARCHAR(max), @listSeparator AS CHAR = ',', @quote AS CHAR = NULL)
	RETURNS @elements TABLE (Position INT, Value VARCHAR(max))
AS
BEGIN
	DECLARE @start   AS INT
	DECLARE @end     AS INT
	DECLARE @element AS VARCHAR(max)
	DECLARE @i       AS INT
	
	IF @list IS NULL RETURN
		
	SET @end   = -1
	SET @start = 0
	SET @i     = 0
	
	WHILE @end <> 0
	BEGIN
		SET @i   = @i + 1
		SET @end = dbo.GetSeparatorIndex(@list, @start, @listSeparator, @quote)
		
		IF @end = 0 
			SET @element = SUBSTRING(@list, @start, LEN(@list) - @start + 1)
		ELSE
			SET @element = SUBSTRING(@list, @start, @end - @start)
		
		SET @start = @end + 1
		
		INSERT @elements VALUES (@i, @element)
	END
	
	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'NextURLCharacter' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE NextURLCharacter
GO

CREATE PROCEDURE NextURLCharacter(@value VARCHAR(max), @index int OUTPUT, @char char OUTPUT)
AS
	SET NOCOUNT on
BEGIN
	SET @char = null
	
	IF @index > LEN(@value) RETURN
	
	SET @char  = SUBSTRING(@value, @index, 1)
	SET @index = @index + 1
	
	IF @char = '%' AND @index < LEN(@value)
	BEGIN
		DECLARE @converted AS CHAR
		
		SELECT @converted = Value FROM dbo.UnpackPairedList('21.!|2A.*|22."|27.''|28.(|29.)|3B.;|3A.:|40.@|26.&|3D.=|2B.+|24.$|2C.,|2F./|3F.?|25.%|23.#|5B.[|5D', '|', '.', NULL) 
		                          WHERE Name = SUBSTRING(@value, @index, 2)
		IF @converted IS NOT NULL
		BEGIN
			SET @char  = @converted
			SET @index = @index + 2
		END 
	END
	ELSE
	   IF @char = '+' SET @char = ' '
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'FirstField' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION FirstField
GO
CREATE FUNCTION FirstField(@list AS VARCHAR(max), @listSeparator AS CHAR = ',', @quote AS CHAR = NULL)
	RETURNS VARCHAR(max)
AS
BEGIN
	DECLARE @field AS VARCHAR(max)
	
	SELECT @field = VALUE FROM dbo.UnpackList(@list, @listSeparator, @quote) WHERE Position = 1
	RETURN @field
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'Anonymize' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION Anonymize
GO

CREATE FUNCTION Anonymize(@value AS VARCHAR(max), @isURL AS CHAR)
	RETURNS VARCHAR(max)
AS
BEGIN		
	DECLARE @index  AS INT
    DECLARE @char   AS CHAR
	DECLARE @strVal AS VARCHAR(max)
	DECLARE @isText AS CHAR
	DECLARE @addCh  AS CHAR
	DECLARE @newAdd AS CHAR
		
	SET @index  = 1
	SET @strVal = ''
	SET @isText = 'N'
	SET @addCh  = 'Y'
	SET @newAdd = 'N'
		
	WHILE @index <= LEN(@value)
		
	BEGIN
		SET @char  = SUBSTRING(@value, @index, 1)
		SET @index = @index + 1
	
		IF @isURL = 'Y'
		BEGIN
			IF @char = '%' AND @index < LEN(@value)
			BEGIN
				DECLARE @converted AS CHAR
		
				SELECT @converted = Value FROM dbo.UnpackPairedList('21.!|2A.*|22."|27.''|28.(|29.)|3B.;|3A.:|40.@|26.&|3D.=|2B.+|24.$|2C.,|2F./|3F.?|25.%|23.#|5B.[|5D', '|', '.', '''') 
				                          WHERE Name = SUBSTRING(@value, @index, 2)
				IF @converted IS NOT NULL
				BEGIN
					SET @char  = @converted
					SET @index = @index + 2
				END 
			END
			ELSE
				IF @char = '+' SET @char = ' '
		END
		
		IF @char < '0' OR @char > '9' SET @isText = 'Y'
			
		IF @char = '%'
		BEGIN
			SET @addCh  = 'Y'
			SET @newAdd = 'Y'
		END
		ELSE
			SET @char = '*'
				
		IF @addCh = 'Y'
		BEGIN
			SET @strVal = @strVal + @char
			SET @addCh  = @newAdd
			SET @newAdd = 'N'
		END	
	END
				
	IF @isText = 'N'
	BEGIN
		IF @value = '' SET @strVal = '' ELSE SET @strVal = 'N'
	END
		
	RETURN @strVal
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'SizeToInt' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION SizeToInt
GO

CREATE FUNCTION SizeToInt(@size AS VARCHAR(max))
	RETURNS BIGINT
AS
BEGIN
	DECLARE @units  AS VARCHAR(max)
	DECLARE @i      AS INT
	DECLARE @dbSize AS FLOAT

	SET @i = CHARINDEX(' ', @size)

	IF @i <> 0
	BEGIN
		SET @units = RIGHT(@size, LEN(@size) - @i)
		SET @size  = LEFT(@size, @i - 1)
	END
	
	SET @dbSize = CAST(@size AS FLOAT)
	
	IF @units = 'KB' SET @dbSize = @dbSize * 1000
	IF @units = 'MB' SET @dbSize = @dbSize * 1000000
	IF @units = 'GB' SET @dbSize = @dbSize * 1000000000
	
	RETURN @dbSize
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetTableStatistics' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE GetTableStatistics
GO

CREATE PROCEDURE GetTableStatistics(@name      SYSNAME, 
                                    @rows      BIGINT OUTPUT, 
                                    @reserved  BIGINT OUTPUT, 
                                    @dataSize  BIGINT OUTPUT, 
                                    @indexSize BIGINT OUTPUT, 
                                    @unused    BIGINT OUTPUT)
AS
BEGIN
	DECLARE @stats TABLE(Name      SYSNAME,
	                     Rows      BIGINT,
	                     Reserved  VARCHAR(100),
	                     DataSize  VARCHAR(100),
	                     IndexSize VARCHAR(100),
	                     Unused    VARCHAR(100))
	INSERT INTO @stats EXEC ('EXEC sp_spaceused ''' + @name + '''')

	SELECT @rows      = Rows, 
	       @reserved  = dbo.SizeToInt(Reserved), 
	       @dataSize  = dbo.SizeToInt(DataSize), 
	       @indexSize = dbo.SizeToInt(IndexSize), 
	       @unused    = dbo.SizeToInt(Unused)
	FROM @stats
	
	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'ParseDBName' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION dbo.ParseDBName
GO

CREATE FUNCTION dbo.ParseDBName(@name AS VARCHAR(max), @getVersion AS CHAR(1))
	RETURNS @parse TABLE ([Database] VARCHAR(128), [Schema] VARCHAR(128), Identifier VARCHAR(128), Version VARCHAR(100))
AS
BEGIN
	DECLARE @field     AS VARCHAR(max)
	DECLARE @separator AS CHAR(1)
	DECLARE @index     AS BIGINT

	SET @index = 1	
	INSERT @parse VALUES(NULL, 'dbo', NULL, NULL)
	
	SELECT @field = Value, @separator = Separator, @index = NextOffset FROM dbo.ExtractField(@name, @index, ' .(', '[]')

	IF @separator = '.'
	BEGIN
		UPDATE @parse SET [Schema] = @field
		SELECT @field = Value, @separator = Separator, @index = NextOffset FROM dbo.ExtractField(@name, @index, ' .(', '[]')
		
		IF @separator = '.'
		BEGIN
			UPDATE @parse SET [Database] = [Schema]
			UPDATE @parse SET [Schema]   = @field
			SELECT @field = Value, @index = NextOffset FROM dbo.ExtractField(@name, @index, ' (', '[]')
		END
	END

	IF @getVersion = 'Y'
	BEGIN
		DECLARE @verIdx AS BIGINT
		
		SET @index = LEN(@field)
	
		WHILE @index > 0
		BEGIN
			DECLARE @ch CHAR

			SET @ch = SUBSTRING(@field, @index, 1)
		
			IF @ch = '_'
				SET @verIdx = @index 
			ELSE IF @ch < '0' OR @ch > '9'
				BREAK
		
			SET @index = @index - 1
		END
		
		IF @verIdx IS NOT NULL
		BEGIN
			UPDATE @parse SET Version    = SUBSTRING(@field, @verIdx + 1, 1000)
			UPDATE @parse SET Identifier = SUBSTRING(@field, 1, @verIdx - 1)
		END
		ELSE
			UPDATE @parse SET Identifier = @field
	END
	ELSE
		UPDATE @parse SET Identifier = @field
	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetLorenzoStoredProcedures' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION dbo.GetLorenzoStoredProcedures
GO

CREATE FUNCTION dbo.GetLorenzoStoredProcedures(@maxVersions INT)
	RETURNS @fields TABLE (Name VARCHAR(100), [Schema] SYSNAME, Identifier SYSNAME, Version VARCHAR(100), Created DATETIME)
AS
BEGIN
	INSERT @fields
	SELECT Name,
		   [Schema],
		   Identifier,
		   Version,
		   Created
	FROM (SELECT Name,
                 Identifier,
                 ST.[Schema],
                 ST.version, 
                 CrDate    AS Created,
                 ROW_NUMBER() OVER (PARTITION BY ST.Identifier ORDER BY ST.Version DESC) AS Row
		  FROM Lorenzo.SYS.SYSOBJECTS 
		  CROSS APPLY dbo.ParseDBName(NAME, 'Y') ST
		  WHERE XTYPE IN ('FN', 'P')) XX
	WHERE Row <= @maxVersions
	ORDER BY Identifier, Row

	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'PrintSQL' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE PrintSQL
GO

CREATE PROCEDURE PrintSQL(@sql NVARCHAR(max))
AS
BEGIN
	DECLARE Line CURSOR LOCAL FAST_FORWARD FOR 
	SELECT Value
		FROM BloodPressure.dbo.UnpackList(@sql, CHAR(13), NULL)
		ORDER BY Position
		
	OPEN Line

	WHILE 0 = 0
	BEGIN
		DECLARE @line AS VARCHAR(max)
		
		FETCH NEXT FROM Line INTO @line
		
		IF @@FETCH_STATUS <> 0 BREAK
		
		PRINT @line
	END
	
	CLOSE Line
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'BackupDatabase' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE BackupDatabase
GO

CREATE PROCEDURE BackupDatabase(@filePrefix AS VARCHAR(max), @database AS SYSNAME, @media AS VARCHAR(max) = 'Backups')
AS
BEGIN
DECLARE @date AS VARCHAR(7)
DECLARE @file AS VARCHAR(max)
DECLARE @name AS VARCHAR(max) = 'Full Backup of ' + @database

SELECT @date = dbo.FormatDate(CURRENT_TIMESTAMP, 'DDMMMYY')
SET    @file = @filePrefix + @date + '.bak'

BACKUP DATABASE @database
TO DISK = @file
   WITH FORMAT,
      MEDIANAME = @media,
      NAME      = @name;
END
GO