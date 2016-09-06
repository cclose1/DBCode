-- Version 1.1
--
-- Version   Date      Author     Description
-- 1.0       01-Feb-09 C.B.Close  Original
-- 1.1       26-Jun-09     "      Added GetXMLAttribute

-- The XML routines do not provide a complete implementation of the XML standard. Only those features required to
-- interpret the AVICode data are implemented. The routines generally have the following initial standard parameters:
--
-- @xml     is the xml document.
-- @index   is the current position in the document and is typically updated by routine.
-- @inCData set to Y if index is currently within a CDATA section, i.e. starts with "<![CDATA[" and ends with "]]>".
--          The value is set to Y on the < that starts the CDATA and is set to N on the first character following
--          the > that terminates the CDATA. Currently only NextXMLChar acts on CDATA. The other functions do
--          not recognise CDATA and may produce incorrect results.

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetXMLAttribute' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION dbo.GetXMLAttribute
GO

-- Returns the value of XML name in attributes or default if attributes does not contain name.
--
-- Note: This is not a rigorous implementation as it does not all for legitimate white space or that
--       the attribute name and value are embedded in another attribute value, i.e. if attributes is x1 = 'value1'
--       then setting name to x1 will fail to return value1 and if attributes is x1="x2='value1'" x2='value1'
--       then setting name to x2 will return value1 and not value2 as it should.

CREATE FUNCTION dbo.GetXMLAttribute(@attributes varchar(max), @name varchar(max), @default varchar(max)=NULL)
   RETURNS varchar(max)
AS
BEGIN
	DECLARE @start int
	DECLARE @end   int
	DECLARE @quote char
	
	SET @quote = '"'
	
	SET @start = CHARINDEX(@name + '=' + @quote, @attributes)
	
	IF @start = 0 
	BEGIN
		SET @quote = ''''
		SET @start = CHARINDEX(@name + '=' + @quote, @attributes)
	END
	
	IF @start = 0 RETURN @default
	
	SET @start = @start + LEN(@name) + 2
	SET @end   = CHARINDEX(@quote, @attributes, @start)
	
	IF @end = 0 SET @end = LEN(@attributes) + 1
	
	RETURN LTRIM(RTRIM(SUBSTRING(@attributes, @start, @end - @start)))
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'RaiseXMLError' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.RaiseXMLError
GO

CREATE PROCEDURE dbo.RaiseXMLError(@xml varchar(max), @index int, @msg varchar(100))
AS
BEGIN
	RAISERROR('At offset %d Error:%s', 11, 1, @index, @msg) 
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'NextXMLChar' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.NextXMLChar
GO

-- Sets @char to next character that is not a discard character.
--
-- Discard characters are CR, LF and if skipSpace = Y space.
--
-- If the index is beyond the end of xml an error if raised. If the end of xml is reached while searching for the
-- next character char will be NULL.
--
-- Note: Tab characters are converted to space.

CREATE PROCEDURE dbo.NextXMLChar(
					@xml       varchar(max),
				    @index     int  OUTPUT,
				    @inCData   char OUTPUT,
				    @skipSpace char,
				    @char      char OUTPUT)
AS
BEGIN
	SET @char = NULL
	
	IF @index > LEN(@xml) EXEC RaiseXMLError @xml, @index, 'Reading beyond the end of the document'

	WHILE @index <= LEN(@xml)
	BEGIN
		SET @char = NULL

		SET @char  = SUBSTRING(@xml, @index, 1)

		IF @inCData = 'N' 
		BEGIN
			IF SUBSTRING(@xml, @index, 9) = '<![CDATA[' SET @inCData = 'Y'
		END
		ELSE
		BEGIN
			IF SUBSTRING(@xml, @index - 3, 3) = ']]>'   SET @inCData = 'N'
		END
		
		SET @index = @index + 1
		
		IF @char <> CHAR(13) AND @char <> CHAR(10)
		BEGIN
			IF @char = CHAR(9) SET @char = ' '

			IF @skipSpace = 'N' OR @char <> ' ' RETURN
		END
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'NextXMLTag' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.NextXMLTag
GO

-- Returns the next XML tag which may either be a start tag, i.e. <tag or an end tag </tag>. When called the only
-- characters that can be present before the first < character are CR, LF, Space or Tag. If this is not the case
-- an error is raised.
--
-- Tag is set to the tag identifier.
--
-- If an  end tag is found N is returned in start.
-- If a start tag is found Y is returned in start and terminator is > or Space if that tag has attributes. If
-- the terminator is Space, i.e. tag has attributes index is positioned to the next character that is not CR, LF,
-- Space or Tab.
--
-- An error is raised if consecutive < characters are found or an end tag is terminated by space rather than >.

CREATE PROCEDURE dbo.NextXMLTag(
					@xml        varchar(max),
				    @index      int          OUTPUT,
				    @inCData    char         OUTPUT,
				    @tag        varchar(max) OUTPUT,
				    @terminator char         OUTPUT,
				    @start      char         OUTPUT)
AS
BEGIN
	DECLARE @skipSpace char

	SET @tag       = NULL
	SET @skipSpace = 'Y'

	WHILE @index <= LEN(@xml)
	BEGIN
		EXEC NextXMLChar @xml, @index OUTPUT, @inCData OUTPUT, @skipSpace, @terminator OUTPUT
		SET @skipSpace = 'N'

		IF @terminator = '>' OR @terminator = ' ' BREAK

		IF @terminator = '<'
		BEGIN
			IF @tag IS NOT NULL EXEC RaiseXMLError @xml, @index, 'Unexpected <'

			SET @tag = ''
		END
		ELSE
		BEGIN
			IF @tag IS NULL
			BEGIN
				DECLARE @msg varchar(100)

				SET @msg = 'Found ' + @terminator + ' while looking for Tag '
				EXEC RaiseXMLError @xml, @index, @msg
			END

			SET @tag = @tag + @terminator
		END
	END

	-- Remove extra spaces

	IF @terminator = ' '
	BEGIN
		EXEC NextXMLChar @xml, @index OUTPUT, @inCData OUTPUT, 'Y', @terminator OUTPUT

		IF @terminator <> '>'
		BEGIN
			-- There are attributes. So reinstate the character removed and the space terminator
			SET @terminator = ' '
			SET @index      = @index - 1
		END
	END

	IF SUBSTRING(@tag, 1, 1) = '/'
	BEGIN
		-- Remove the / and error if the terminator is not > as end tags can't have attributes

		IF @terminator <> '>' EXEC RaiseXMLError @xml, @index, 'End tags cannot have attributes'

		SET @tag   = SUBSTRING(@tag, 2, LEN(@tag) -1)
		SET @start = 'N'
	END
	ELSE
		SET @start = 'Y'
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetXMLValue' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.GetXMLValue
GO

-- Returns the value for the next tag.
--
-- If requiredTag is not null no action is taken if the next tag is not equal to requiredTag other than state is set to M
-- and tag is set to the identifier if the next tag.
--
-- State is returned with one of the following values
--	O the tag is a start tag containing nested tags.
--  C the tag is a closing tag.
--  B the tag is a start tag containing a value only. In this case the end tag is removed.
--  M the required tag is not the next tag.
--
-- For states O and B the attributes and value may be set. For state C both value and attribute will be NULL

CREATE PROCEDURE dbo.GetXMLValue(
					@xml         varchar(max),
				    @index       int          OUTPUT,
				    @inCData     char         OUTPUT,
				    @requiredTag varchar(max),
				    @tag         varchar(max) OUTPUT,
				    @attributes  varchar(max) OUTPUT,
				    @value       varchar(max) OUTPUT,
                    @state       char         OUTPUT)
AS
BEGIN
	DECLARE @term    char
	DECLARE @endTag  varchar(max)
	DECLARE @i       int
	DECLARE @start   char
	DECLARE @inIndex int 

	SET @tag        = NULL
	SET @state      = 'B'
	SET @value      = NULL
	SET @attributes = NULL
	SET @inIndex    = @index
	EXEC NextXMLTag @xml, @index OUTPUT, @inCData OUTPUT, @tag OUTPUT, @term OUTPUT, @start OUTPUT

	IF @term = ' '
	BEGIN
		DECLARE @inQuote char

		-- There are attributes

		SET @attributes = ''
		SET @inQuote    = 'N'

		WHILE 0=0
		BEGIN
			EXEC NextXMLChar @xml, @index OUTPUT, @inCData OUTPUT, 'N', @term OUTPUT

			IF @term = '"'
			BEGIN
				IF @inQuote = 'N' SET @inQuote = 'Y' ELSE SET @inQuote = 'N'
			END
			ELSE
			BEGIN
				IF @inQuote = 'N'
				BEGIN
					IF @term = '>' BREAK

					IF @term = '/'
					BEGIN
						SET @state = 'R'
						EXEC NextXMLChar @xml, @index OUTPUT, @inCData OUTPUT, 'N', @term OUTPUT

						IF @term = '>' BREAK

						EXEC RaiseXMLError @xml, @index, 'Expecting > following / while extracting attributes'
					END
				END
			END

			SET @attributes = @attributes + @term
		END
	END

	IF @requiredTag IS NOT NULL AND (@tag <> @requiredTag OR @state = 'C')
	BEGIN
		SET @state      = 'M'
		SET @attributes = NULL
		SET @index      = @inIndex
		RETURN
	END
	
	IF @state = 'R'
	BEGIN
		SET @state = 'B'
		RETURN
	END

	IF @start = 'N' 
	BEGIN
		SET @state = 'C'
		RETURN
	END

	-- Now extract the value

	SET @value = ''

	WHILE 0=0
	BEGIN
		EXEC NextXMLChar @xml, @index OUTPUT, @inCData OUTPUT, 'N', @term OUTPUT

		IF @term = '<' BREAK

		SET @value = @value + @term
	END

	-- Set the tag state to open and reposition pointer to the < character

	SET @state = 'O'
	SET @index = @index - 1
	SET @i     = @index

	-- Now look to see if there is a matching end tag

	EXEC NextXMLTag @xml, @index OUTPUT, @inCData OUTPUT, @endTag OUTPUT, @term OUTPUT, @start OUTPUT

	IF @start = 'Y'
	BEGIN
		SET @index = @i
		RETURN
	END

	IF @endTag <> @tag
	BEGIN
		DECLARE @msg varchar(256)

		SET @msg = 'End tag ' + @endTag + ' does not match start tag ' + @tag
		EXEC RaiseXMLError @xml, @index, @msg
	END

	SET @state = 'B'
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'DiscardXMLTag' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.DiscardXMLTag
GO

-- Discards all the enclosed tags until the first unmatched closing tag is found. If @tag is not NULL an error
-- is raised if the closing tag is not the same as tag.

CREATE PROCEDURE dbo.DiscardXMLTag(@xml varchar(max), @index int OUTPUT, @inCData char OUTPUT, @tag varchar(max))
AS
BEGIN
	DECLARE @endTag     varchar(max)
	DECLARE @attributes varchar(max)
	DECLARE @value      varchar(max)
	DECLARE @msg        varchar(8000)
	DECLARE @state      char
	DECLARE @level      int

	SET @level = 0

	WHILE 0=0
	BEGIN
		EXEC GetXMLValue @xml, @index OUTPUT, @inCData OUTPUT, NULL, @endTag OUTPUT, @attributes OUTPUT, @value OUTPUT, @state OUTPUT

		IF @state = 'C'
		BEGIN
			IF @level = 0 BREAK

			SET @level = @level - 1
		END

		IF @state = 'O' SET @level = @level + 1
	END

	IF @tag IS NULL OR @tag = @endTag RETURN

	SET @msg = 'Discard end tag ' + @endTag + ' does not match start tag ' + @tag
	EXEC RaiseXMLError @xml, @index, @msg
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'QualifyTable' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION dbo.QualifyTable
GO

-- Returns the fully qualified reference for table for CSCDatabase entry for databaseId.
--
-- NULL is returned if there is no CSCDatabase entry for databaseId.

CREATE FUNCTION dbo.QualifyTable(@databaseId int, @table sysname)
   RETURNS varchar(1000)
AS
BEGIN
	DECLARE @dbName    sysname
	DECLARE @server    sysname
	DECLARE @schema    sysname
	DECLARE @qualified VARCHAR(1000)
	
	SELECT @dbName = [Database],
           @server = Server,
           @schema = [Schema]
    FROM CSCDatabase WHERE Id = @databaseId
    
    IF @dbName IS NULL RETURN NULL
    
    IF @server IS NULL
	    SET @qualified = '[' + @dbName + '].[' + @schema + '].' + @table
	ELSE
	    SET @qualified = '[' + @server + '].[' + @dbName + '].[' + @schema + '].' + @table
	    
	RETURN @qualified
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetdatabaseId' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.GetdatabaseId
GO

CREATE PROCEDURE dbo.GetdatabaseId(@Database varchar(255), @databaseId int OUTPUT)
AS
BEGIN	
	SELECT @databaseId = Id FROM CSCDatabase WHERE Name = @Database AND [Current] = 'Y'
	
	IF @databaseId IS NULL RAISERROR('Database %s not found in CSCDatabase', 11, 1, @Database)
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'NextField' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
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

CREATE PROCEDURE dbo.NextField (
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
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetFunctionId' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.GetFunctionId
GO

CREATE PROCEDURE dbo.GetFunctionId(@timestamp  datetime,
                                   @type       varchar(20),
                                   @name       varchar(max),
                                   @functionId int OUTPUT)
AS
BEGIN
	DECLARE @version varchar(20)
	DECLARE @i       int
	DECLARE @sep     char
	DECLARE @field   varchar(max)
	
	SET @version = NULL

	IF @type IS NULL
	BEGIN
		SET @i = 1
		EXEC NextField @name, @i OUTPUT, ':.', @type OUTPUT, @sep OUTPUT, '[]'
		
		IF @sep = '.' AND @type = 'dbo'
			SET @type = 'SQL'
		ELSE IF @sep IS NULL OR @sep = '.'
		BEGIN
			SET @type = NULL
			SET @i    = 1
		END
		
		IF @sep IS NULL
			SET @type = NULL
		ELSE IF @i > 1
			SET @name = SUBSTRING(@name, @i, LEN(@name) - @i + 1)
	END

	IF @type = 'SQL' OR @type IS NULL
	BEGIN
		DECLARE @uscore int
		
		SET @uscore = 0
		SET @i      = 1
		
		WHILE @i <= LEN(@name)
		BEGIN
			DECLARE @ch AS CHAR
			
			SET @ch = SUBSTRING(@name, @i, 1)
			
			IF @ch = '_'
			BEGIN
				IF @uscore = 0 SET @uscore = @i
			END
			ELSE IF @ch < '0' OR @ch > '9' SET @uscore = 0
			
			SET @i = @i + 1
		END
			
		IF @uscore <> 0 
		BEGIN
			SET @version = SUBSTRING(@name, @uscore + 1, LEN(@name) - @uscore + 2)
			SET @name    = SUBSTRING(@name, 1, @uscore - 1)
			SET @type    = 'SQL'
		END
		
		IF @type IS NULL SET @type = 'METHOD'
	END
	
	SET @name = LTRIM(RTRIM(@name))
	SET @type = LTRIM(RTRIM(@type))
	SET @functionId = NULL
	SELECT @functionId = FunctionId FROM CSCFunction WITH (NOLOCK) 
									WHERE Type    = @type
									AND   Name    = @name
									AND  (Version = @version OR Version IS NULL)
	IF @functionId IS NULL
	BEGIN
		BEGIN TRY
			INSERT INTO CSCFunction
							(Type,
						     Name,
					         Version,
					         Discovered)
						VALUES
							(@type,
							 @name,
							 @version,
							 @timestamp)
		END TRY
		BEGIN CATCH
			DECLARE @errorNumber    AS INT
			DECLARE @errorSeverity  AS INT
			DECLARE @errorState     AS INT
			DECLARE @errorProcedure AS NVARCHAR(max)
			DECLARE @errorLine      AS INT
			DECLARE @errorMessage   AS NVARCHAR(max)
			
			SELECT
				@errorNumber    = ERROR_NUMBER(),
				@errorSeverity  = ERROR_SEVERITY(),
				@errorState     = ERROR_STATE(),
				@errorProcedure = ERROR_PROCEDURE(),
				@errorLine      = ERROR_LINE(),
				@errorMessage   = ERROR_MESSAGE()
				
				RAISERROR(
					'In %s(%i) error (%i.%s) Creating function for %s',
					@errorSeverity,
					@errorState,
					@errorProcedure,
					@errorLine, 
					@errorNumber, 
					@errorMessage,
					@name)
				RETURN
		END CATCH
		
		SELECT @functionId = FunctionId FROM CSCFunction WITH (NOLOCK) 
										WHERE Type    = @type
										AND   Name    = @name
										AND  (Version = @version OR Version IS NULL)
	END

	IF NOT EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'#fids') AND OBJECTPROPERTY(id, N'#fids') = 1) RETURN

	IF NOT EXISTS (SELECT Id FROM #fids WHERE Id = @functionId) INSERT INTO #fids VALUES (@functionId)
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UpdateServer' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.UpdateServer
GO

CREATE PROCEDURE dbo.UpdateServer(
						@name        VARCHAR(180),  
						@environment VARCHAR(50),
						@tower       VARCHAR(10),
						@type        VARCHAR(30),
						@manIP       VARCHAR(50),
						@prodIP      VARCHAR(50),
						@refresh     CHAR     = 'N',
						@removed     DATETIME = NULL)
AS
	SET NOCOUNT ON
BEGIN
	DECLARE @currentEnv    AS VARCHAR(50)
	DECLARE @currentType   AS VARCHAR(30)
	DECLARE @currentManIP  AS VARCHAR(50)
	DECLARE @currentProdIP AS VARCHAR(50)
	DECLARE @currentTower  AS VARCHAR(50)
	DECLARE @seqNo         AS INT
	
	SELECT 
		@seqNo         = SeqNo,
		@currentEnv    = Environment,
		@currentType   = Type,
		@currentManIP  = ManIP,
		@currentProdIP = ProdIP,
		@currentTower  = Tower
	FROM CSCServer 
	WHERE Name    = @name
	AND   Removed IS NULL
	
	IF @seqNo IS NULL AND (@refresh = 'N' OR @refresh IS NULL)
	BEGIN
		PRINT 'Server ' + @name + ' Not found in CSCServer'
		RETURN
	END
	
	IF NOT EXISTS (SELECT Environment FROM CSCEnvironment WHERE Environment = @environment)
	BEGIN
		INSERT CSCEnvironment VALUES(@environment, NULL, 'N', 100, 1.50, 20.00, 100, 0.50, 20.00)
		PRINT 'Created entry in CSCEnvironment for ' + @environment
	END
	
	IF @seqNo IS NULL
	BEGIN
		INSERT CSCServer
				(Name,  Type,  Environment,  ManIP,  ProdIP,  Tower,  Ignore, Deployed)
		VALUES
				(@name, @type, @environment, @manIP, @prodIP, @tower, 'N',    CURRENT_TIMESTAMP)
		PRINT 'Server ' + @name + ' Created entry with id ' + LTRIM(STR(@@IDENTITY))
	END
	ELSE IF @currentEnv = 'Unknown' OR @refresh = 'Y'
	BEGIN
		UPDATE CSCServer
			SET Environment = @environment,
				Tower       = @tower,
				Type        = @type,
				ManIP       = @manIP,
				ProdIP      = @prodIP
		WHERE SeqNo = @seqNo
		PRINT 'Server ' + @name + ' Updated'
	END
	ELSE IF 
		@environment <> @currentEnv   OR
		@tower       <> @currentTower OR
		@type        <> @currentType  OR
		@manIP       <> @currentManIP OR
		@prodIP      <> @currentProdIP
	BEGIN
		IF @removed IS NULL 
			PRINT 'Server ' + @name + ' To change the details for an existing server, @removed must be supplied or @refresh set to Y' 
		ELSE
		BEGIN
			BEGIN TRANSACTION
			UPDATE CSCServer SET Removed = @removed WHERE SeqNo = @seqNo
			INSERT CSCServer
					(Name,  Type,  Environment,  ManIP,  ProdIP,  Tower,  Ignore, Deployed)
			VALUES
					(@name, @type, @environment, @manIP, @prodIP, @tower, 'N',    @removed)
			COMMIT
			PRINT 'Server ' + @name + ' Created new version with id ' + LTRIM(STR(@@IDENTITY))
		END		
	END
	ELSE
		PRINT 'Server ' + @name + ' Details not changed'
END
GO
