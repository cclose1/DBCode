USE BloodPressure
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.Test') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.Test
GO
CREATE FUNCTION dbo.Test(@dateString AS VARCHAR(max))
	RETURNS VARCHAR(max)
AS
BEGIN
	RETURN @dateString
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.SetFromAs') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.SetFromAs
GO
CREATE FUNCTION dbo.SetFromAs(
			@prefix AS SYSNAME,
			@table  AS SYSNAME,
			@alias  AS SYSNAME)
	RETURNS VARCHAR(max)
AS
BEGIN
	IF CHARINDEX('#', @prefix) = 1
		SET @table = @prefix
	ELSE IF @prefix IS NOT NULL
		SET @table = @prefix + '.' + @table
	
	IF @alias IS NOT NULL SET @table += ' AS ' + @alias

	RETURN @table
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.TestDate') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.SetAlias
GO
CREATE FUNCTION dbo.SetAlias(@alias AS SYSNAME, @identifier AS SYSNAME)
	RETURNS VARCHAR(max)
AS
BEGIN
	IF @alias IS NOT NULL SET @identifier = @alias + '.' + @identifier

	RETURN @identifier
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.TestDate') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.TestDate
GO
CREATE FUNCTION dbo.TestDate(@dateString AS DATETIME)
	RETURNS VARCHAR(max)
AS
BEGIN
	RETURN @dateString
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.TruncateFractionalSeconds') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.TruncateFractionalSeconds
GO
CREATE FUNCTION dbo.TruncateFractionalSeconds(@value AS VARCHAR(max), @length AS INT = 3)
	RETURNS VARCHAR(max)
AS
BEGIN
	DECLARE @offset AS INT = CHARINDEX('.', @value)
	
	DECLARE @left  AS VARCHAR(max)
	DECLARE @right AS VARCHAR(max)

	IF @offset = 0
	BEGIN
		SET @left = @value
		SET @right = ''
	END
	ELSE
	BEGIN
		SET @left  = SUBSTRING(@value, 1, @offset - 1)
		SET @right = SUBSTRING(@value, @offset + 1, LEN(@value) - @offset + 1)
	END
	
	IF LEN(@right) > @length
		SET @right = SUBSTRING(@right, 1, @length)
	ELSE
		SET @right = dbo.rpad(@right, @length, '0')

	SET @value = @left + '.' + @right

	RETURN @value
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.StringToDate') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.StringToDate
GO
--
-- This function is primarily introduced to handle that datetime strings derived for datetime values from linked servers
-- are not necessarily valid. For MySQL the fractional seconds are given to 7 places, whereas SQL Server accepts at most 3.
-- This is not an ideal solution as other servers may not work in the same way.
--
CREATE FUNCTION dbo.StringToDate(@dateString AS VARCHAR(max))
	RETURNS DATETIME
AS
BEGIN
	RETURN CONVERT(DATETIME, dbo.TruncateFractionalSeconds(@dateString, DEFAULT), 102)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.CompareValue') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.CompareValue
GO
CREATE FUNCTION dbo.CompareValue(@type AS SYSNAME, @lValue AS VARCHAR(max), @rValue AS VARCHAR(max))
RETURNS CHAR
AS
BEGIN
	DECLARE @match AS CHAR = 'N'

	IF @lValue IS NULL AND @lValue IS NULL
		SET @match = 'Y'
	ELSE IF @type IN ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext')
	BEGIN
		IF @lValue COLLATE DATABASE_DEFAULT = @rValue SET @match = 'Y'
	END
	ELSE IF @type = 'datetime' AND @lvalue IS NOT NULL AND @rValue IS NOT NULL
	BEGIN
		IF dbo.StringToDate(@lValue) = dbo.StringToDate(@rValue) SET @match = 'Y'
	END
	ELSE IF @type = 'time' AND @lvalue IS NOT NULL AND @rValue IS NOT NULL
	BEGIN
		IF dbo.TruncateFractionalSeconds(@lValue, DEFAULT) = dbo.TruncateFractionalSeconds(@rValue, DEFAULT) SET @match = 'Y'
	END
	ELSE
		IF @lValue = @rValue SET @match = 'Y'
	--
	-- The following has been added to account for that when using jdbc a MYSQL char field set to NULL is converted
	-- to an empty string rather than NULL.
	--
	IF @type = 'char' AND @match = 'N'
	BEGIN
		IF @lValue IS NULL AND LEN(@rValue) = 0 OR @rValue IS NULL AND LEN(@lValue) = 0 SET @match = 'Y'
	END

	RETURN @match
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.AddCreateTableRow') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.AddCreateTableRow
GO
CREATE FUNCTION dbo.AddCreateTableRow( 
					@column    AS SYSNAME, 
					@type      AS SYSNAME,
					@size      AS INT,
					@precision AS INT,
					@scale     AS INT,
					@separator AS CHAR,
					@indent    AS INT,
					@namePad   AS INT,
					@typePad   AS INT,
					@allowNull AS CHAR)
	RETURNS VARCHAR(max)
AS
BEGIN
	DECLARE @sql    AS NVARCHAR(max)
	DECLARE @prefix AS VARCHAR(max) = ' '
	
	SET @prefix = dbo.lpad(@prefix, @indent, ' ')
	SET @sql    = @separator + CHAR(13) + @prefix + dbo.rpad(@column, @namePad, ' ') + ' '

	IF @type IN ('VARCHAR', 'NCHAR') 
		SET @type += '(' + CASE WHEN @size = -1 THEN 'max' ELSE + CAST(@size AS VARCHAR) END + ')'
	ELSE IF @type IN ('DECIMAL', 'NUMERIC') AND @precision <> 0
		SET @type += '(' + CAST(@precision AS VARCHAR) + ', ' + CAST(@scale AS VARCHAR) + ')'
	
	SET @sql += dbo.rpad(@type, @typePad, ' ') + ' '
	
	IF @allowNull = 'Y' 
		SET @sql += 'NULL' 
	ELSE
		SET @sql += 'NOT NULL'
		
	RETURN @sql
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.AddSetField') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.AddSetField
GO
CREATE FUNCTION dbo.AddSetField( 
					@column    AS SYSNAME, 
					@value     AS SYSNAME,
					@namePad   AS INT)
	RETURNS VARCHAR(max)
AS
BEGIN
	DECLARE @sql AS NVARCHAR(max)
	
	SELECT @sql = dbo.rpad(dbo.ConvertReserved(@column), @namePad, ' ') + ' = ' + dbo.ConvertReserved(@value)
	
	RETURN @sql
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.AddSelectField') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.AddSelectField
GO
CREATE FUNCTION dbo.AddSelectField( 
					@column    AS SYSNAME, 
					@alias     AS SYSNAME,
					@separator AS CHAR,
					@indent    AS INT,
					@namePad   AS INT)
	RETURNS VARCHAR(max)
AS
BEGIN
	DECLARE @sql    AS NVARCHAR(max)
	DECLARE @prefix AS VARCHAR(max) = ' '
	
	SET @prefix = dbo.lpad(@prefix, @indent, ' ')
	SET @sql    = @separator + CHAR(13) + @prefix
	SET @column = dbo.ConvertReserved(@column)
	SET @alias  = dbo.ConvertReserved(@alias)
	
	IF @alias IS NULL
		SET @sql += @column
	ELSE
		SET @sql += dbo.rpad(@column, @namePad, ' ') + ' AS ' + @alias
		
	RETURN @sql
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.AddCollate') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.AddCollate
GO
CREATE FUNCTION dbo.AddCollate(@type AS SYSNAME)
	RETURNS VARCHAR(max)
AS
BEGIN
	IF @type IN ('char', 'varchar', 'text', 'nchar', 'nvarchar', 'ntext') RETURN ' COLLATE DATABASE_DEFAULT'
	
	RETURN ''
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.AddCondition') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.AddCondition
GO
CREATE FUNCTION dbo.AddCondition(
					@test      AS SYSNAME,
					@lAlias    AS SYSNAME,
					@rAlias    AS SYSNAME,
					@column    AS SYSNAME, 
					@type      AS SYSNAME,
					@indent    AS INT,
					@namePad   AS INT,
					@nullable  AS CHAR)
	RETURNS VARCHAR(max)
AS
BEGIN
	DECLARE @sql    AS NVARCHAR(max)
	DECLARE @prefix AS VARCHAR(max) = ' '
	DECLARE @lName  AS SYSNAME
	DECLARE @rName  AS SYSNAME

	DECLARE @new    AS CHAR = 'Y'
	
	SET @prefix = dbo.lpad(@prefix, @indent, ' ')
	SET @sql    = @prefix
	SET @column = dbo.ConvertReserved(@column)
	
	SET @prefix = ''
	
	SET @lName = dbo.rpad(dbo.SetAlias(@lAlias, @column), @namePad, ' ')
	SET @rName = dbo.rpad(dbo.SetAlias(@rAlias, @column), @namePad, ' ')
			
	IF @test = 'IS NULL'
		SET @sql +=  @prefix + @lName + ' ' + @test + ' '
	ELSE IF @new = 'Y'
	BEGIN
		IF @type = 'datetime' SET @rName = 'CONVERT(VARCHAR, ' + @rName + ', 21)'

		SET @sql = ' dbo.CompareValue(''' + @type + ''',' +  @lName + ',' + @rName + ') = ''' + IIF(@test = '<>', 'N''', 'Y''')
	END
	ELSE
	BEGIN
		IF @nullable = 'Y'
			SET @sql   += '('
		ELSE
			SET @sql += ' '

		SET @sql += @prefix + @lName + ' ' + @test + ' ' + dbo.rpad(@rName, @namePad, ' ') + dbo.AddCollate(@type)
		
		IF @nullable = 'Y'
		BEGIN
			IF @test = '<>' 
				SET @sql += ' OR ' + @lName + ' IS NOT NULL AND ' + @rName + ' IS NULL OR ' + @lName + ' IS NULL AND ' + @rName + ' IS NOT NULL'
			ELSE
				SET @sql += ' OR ' + @lName + ' IS NULL AND ' + @rName + ' IS NULL'
		
			SET @sql += ')'
		END
	END
	
	RETURN @sql
END
GO

IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'AddFromJoin' AND type ='p')
BEGIN
	DROP Procedure dbo.AddFromJoin
END
GO
CREATE PROCEDURE dbo.AddFromJoin(
			@sql       AS NVARCHAR(max) OUTPUT,
			@from      AS SYSNAME,
			@fromAlias AS SYSNAME,
			@to        AS SYSNAME,
			@toAlias   AS SYSNAME,
			@table     AS SYSNAME,
			@join      AS SYSNAME,
			@whereCond AS VARCHAR(10),
			@whereTest AS VARCHAR(10),
			@keyWhere  AS CHAR = 'Y')
AS
BEGIN
	DECLARE @clause  AS NVARCHAR(max)
	DECLARE @namePad AS INT = 15
	
	SET @sql += CHAR(13) + 'FROM ' + dbo.SetFromAs(@from, @table, @fromAlias) + CHAR(13) + @join + ' ' + dbo.SetFromAs(@to, @table, @toAlias) + CHAR(13) + 'ON  '
	
	SELECT @clause = COALESCE(@clause + CHAR(13) + 'AND ' + @fromAlias + '.', @fromAlias + '.') + dbo.rpad(dbo.ConvertReserved([Column]), @namePad, ' ') + ' = ' + @toAlias + '.' + dbo.ConvertReserved([Column]) + dbo.AddCollate([Type]) FROM #TableDetails WHERE [Key] ='Y' ORDER BY Id
	
	SET @sql += @clause
	
	IF @whereCond IS NOT NULL
	BEGIN
		SET @whereCond = dbo.rpad(@whereCond, 5, ' ')
		SET @sql += CHAR(13) + 'WHERE'
		SET @clause = NULL
		SELECT @clause = COALESCE(@clause + CHAR(13) + @whereCond, '') + dbo.AddCondition(@whereTest, @fromAlias, @toAlias, [Column], [Type], 1, @namePad, Nullable) FROM #TableDetails WHERE [Key] = @keyWhere ORDER BY Id
		SET @sql += @clause
	END
END
GO

IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'LoadTableDetails' AND type ='p')
BEGIN
	DROP Procedure dbo.LoadTableDetails
END
GO
CREATE PROCEDURE LoadTableDetails(
					@database       AS SYSNAME, 
					@table          AS SYSNAME, 
					@index          AS SYSNAME = NULL, 
					@allowComputed  AS CHAR    = 'N',
					@allowIdentity  AS CHAR    = 'N',
					@escapeReserved AS CHAR    = 'Y')
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sql   AS VARCHAR(max)
	DECLARE @msg   AS VARCHAR(max)
	DECLARE @error AS INT
	DECLARE @rows  AS INT
	
	SET @sql = '
		INSERT #TableDetails
		SELECT 
			ST.object_id,
			SC.column_id,
			'
	IF @escapeReserved = 'Y'	
		SET @sql += 'dbo.ConvertReserved(SC.name),' 
	ELSE
		SET @sql += 'SC.name,'
		
	SET @sql += '
			''N'',
			TY.Name,
			sc.max_length,
			sc.precision,
			sc.scale,
			CASE WHEN SC.is_nullable = 1 THEN ''Y'' ELSE ''N'' END,
			CASE WHEN SC.is_identity = 1 THEN ''Y'' ELSE ''N'' END,
			CASE WHEN SC.is_computed = 1 THEN ''Y'' ELSE ''N'' END
		FROM ' + @database + '.sys.tables ST
		INNER JOIN ' + @database + '.sys.columns SC 
		ON ST.object_id = SC.object_id
		INNER JOIN ' + @database + '.sys.types TY 
		ON TY.user_type_id = SC.user_type_id
		WHERE ST.name = ''' + @table + '''
		AND   SC.is_computed <> 1'
	EXEC (@sql)
	SELECT @error = @@ERROR, @rows = @@ROWCOUNT
		
	IF @rows = 0 
	BEGIN
		SET @msg = 'Table %s not in database %s';
		RAISERROR (@msg, 11, 1, @table, @database);
	END 
		
	SET @sql = '		
		UPDATE TB
			SET [Key] = ''Y''
		FROM #TableDetails TB
		JOIN ' + @database + '.sys.indexes IX
		ON TB.ObjectId = IX.object_id
		JOIN ' + @database + '.sys.index_columns IC
		ON  IC.object_id = IX.object_id
		AND IC.index_id  = IX.index_id
		AND IC.column_id = TB.id
		WHERE '
	
	IF @index IS NULL
		SET @sql += 'IX.is_primary_key = 1'
	ELSE
		SET @sql += 'IX.name = ''' + @index + ''''
	EXEC (@sql)
	SELECT @rows = @@ROWCOUNT
		
	IF @rows = 0
	BEGIN
		DECLARE @idx AS SYSNAME = COALESCE(@index, 'PRIMARY KEY')
		
		SET @msg = 'Index %s does not exist on table %s in database %s';
		RAISERROR (@msg, 11, 1, @idx, @table, @database);
	END
		
	SET @index = ISNULL(@index, 'PRIMARY KEY')
	
	IF @allowComputed = 'N'
	BEGIN
		SELECT 
			@rows = COUNT(*) 
		FROM #TableDetails
		WHERE [Key] = 'Y' AND IsComputed = 'Y'
		
		IF @rows <> 0
		BEGIN
			SET @msg   = 'Index %s for table %s in database %s has computed column(s)';
			RAISERROR (@msg, 11, 1, @index, @table, @database);
		END
		
		DELETE #TableDetails WHERE IsComputed = 'Y'
	END
		
	IF @allowIdentity = 'N'
	BEGIN
		SELECT 
			@rows = COUNT(*) 
		FROM #TableDetails
		WHERE [Key] = 'Y' AND IsIdentity = 'Y'
		
		IF @rows <> 0
		BEGIN
			SET @msg = 'Index %s for table %s in database %s has identity column(s)';
			RAISERROR (@msg, 11, 1, @index, @table, @database);
		END
		
		DELETE #TableDetails WHERE IsIdentity = 'Y'
	END
END
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'UpdateTable' AND type ='p')
BEGIN
	DROP Procedure dbo.UpdateTable
END
GO
CREATE PROCEDURE UpdateTable(
					@target       AS SYSNAME, 
					@targetPrefix AS SYSNAME, 
					@sourcePrefix AS SYSNAME, 
					@table        AS SYSNAME,
					@printSQL     AS CHAR  = 'Y')
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sql    AS NVARCHAR(max)

	SELECT @sql = COALESCE(@sql + ',' + CHAR(13) + '       ', '   SET ') + dbo.AddSetField([Column], @sourcePrefix + [Column], 14) FROM #TableDetails WHERE [Key] = 'N' ORDER BY Id

	SET @sql  = CHAR(13) + 'UPDATE TR ' + CHAR(13) + @sql

	EXEC dbo.AddFromJoin
			@sql       OUTPUT,
			'#Changes',
			'CH',
			@target,
			'TR',
			@table,
			'JOIN',
			NULL,
			NULL,
			NULL

	IF @printSQL = 'Y' EXEC PrintSQL @sql

	EXEC (@sql)
END
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'CompareTable' AND type ='p')
BEGIN
	DROP Procedure dbo.CompareTable
END
GO
CREATE PROCEDURE CompareTable(
					@SQLServer     AS SYSNAME, 
					@MySQL         AS SYSNAME, 
					@table         AS SYSNAME, 
					@key           AS SYSNAME     = NULL, 
					@update        AS VARCHAR(10) = NULL,
					@allowIdentity AS CHAR        = 'N',
					@printSQL      AS CHAR        = 'N')
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sql    AS NVARCHAR(max)
	DECLARE @clause AS NVARCHAR(max)
	
	CREATE TABLE #TableDetails (
		ObjectId   INT,
		Id         INT,
		[Column]   SYSNAME,
		[Key]      CHAR,
		[Type]     SYSNAME NULL,
		Size       INT     NULL,
		Precision  INT     NULL,
		Scale      INT     NULL,
		Nullable   CHAR,
		IsIdentity CHAR,
		IsComputed CHAR)
	EXEC LoadTableDetails @SQLServer, @table, @key, @allowIdentity = @allowIdentity, @escapeReserved = 'N'
	SET @SQLServer += '.dbo'
	SET @sql  = 'CREATE TABLE #Changes' + dbo.AddCreateTableRow('Id', 'INT IDENTITY(1,1)', -1, 0, 0, '(', 4, 15, 15, 'N')
	SET @sql += dbo.AddCreateTableRow('[!Target]',  'VARCHAR', 20, 0, 0, ',', 4, 15, 15, 'N')
	SET @sql += dbo.AddCreateTableRow('[Table]',    'VARCHAR', 20, 0, 0, ',', 4, 15, 15, 'N')
	SELECT @sql = @sql + dbo.AddCreateTableRow([Column], [Type], Size, Precision, Scale, ',', 4, 15, 15, 'N')           FROM #TableDetails WHERE [Key] ='Y' ORDER BY Id
	SELECT @sql = @sql + dbo.AddCreateTableRow('SQL'   + [Column], [Type], Size, Precision, Scale, ',', 4, 15, 15, 'Y') FROM #TableDetails WHERE [Key] ='N' ORDER BY Id
	SELECT @sql = @sql + dbo.AddCreateTableRow('MySQL' + [Column], [Type], Size, Precision, Scale, ',', 4, 15, 15, 'Y') FROM #TableDetails WHERE [Key] ='N' ORDER BY Id
	SET @sql += ')' + CHAR(13) + 'INSERT #Changes ' + CHAR(13) + 'SELECT ' + CHAR(13) + '   ''' + @MySQL + ''',' + CHAR(13) + '   ''' + @table + ''''
	SELECT @sql = @sql + ',S.' + dbo.ConvertReserved([Column]) FROM #TableDetails WHERE [Key] = 'Y' ORDER BY Id
	SELECT @sql = @sql + ',S.' + dbo.ConvertReserved([Column]) FROM #TableDetails WHERE [Key] = 'N' ORDER BY Id
	SELECT @sql = @sql + ',M.' + dbo.ConvertReserved([Column]) FROM #TableDetails WHERE [Key] = 'N' ORDER BY Id
	
	EXEC dbo.AddFromJoin
			@sql       OUTPUT,
			@MySQL,
			'M',
			@SQLServer,
			'S',
			@table,
			'JOIN',
			'OR',
			'<>',
			'N'
	SET @sql += CHAR(13) + 'IF @@ROWCOUNT = 0 '
	SET @sql += CHAR(13) + '   PRINT ''Table ' + dbo.rpad(@table, 20, ' ') + ' matches in databases ' + dbo.rpad(dbo.FirstField(@SQLServer, '.', 'N'), 15, ' ') + ' and ' + dbo.FirstField(@MySQL, '.', 'N') + ''''
	SET @sql += CHAR(13) + 'ELSE' + CHAR(13) + 'BEGIN'
	SET @clause = 'SELECT'
	SET @clause += dbo.AddSelectField('Id',        NULL,     '',  5, 20)
	SET @clause += dbo.AddSelectField('[!Target]', NULL,     ',', 5, 20)
	SET @clause += dbo.AddSelectField('[Table]',   NULL,     ',', 5, 20)
	SET @clause += dbo.AddSelectField('''MySQL''', 'Server', ',', 5, 20)
	SELECT @clause = @clause + dbo.AddSelectField([Column],           NULL,     ',', 5, 20) FROM #TableDetails WHERE [Key] = 'Y'
	SELECT @clause = @clause + dbo.AddSelectField('MySQL' + [Column], [Column], ',', 5, 20) FROM #TableDetails WHERE [Key] = 'N' ORDER BY Id
	SET @clause += CHAR(13) + 'FROM #Changes' + CHAR(13) + 'UNION' + CHAR(13) + 'SELECT'
	SET @clause += dbo.AddSelectField('Id',         NULL,     '',  5, 20)
	SET @clause += dbo.AddSelectField('[!Target]',  NULL,     ',', 5, 20)
	SET @clause += dbo.AddSelectField('[Table]',    NULL,     ',', 5, 20)
	SET @clause += dbo.AddSelectField('''SQL''',    'Server', ',', 5, 20)
	SELECT @clause = @clause + dbo.AddSelectField([Column],         NULL,     ',', 5, 20) FROM #TableDetails WHERE [Key] = 'Y'
	SELECT @clause = @clause + dbo.AddSelectField('SQL' + [Column], [Column], ',', 5, 20) FROM #TableDetails WHERE [Key] = 'N' ORDER BY Id
	SET @clause += CHAR(13) + 'FROM #Changes' + CHAR(13) + 'ORDER BY Id, [Server]'
	SET @sql    += CHAR(13) + @clause
	
	IF @update = 'MySQL'
	BEGIN
		SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
		SET @sql += CHAR(13) + 'EXEC UpdateTable ''' + @MySQL + ''', ''MySQL'', ''SQL'', ''' + @table + ''', ''' + @printSQL + ''''
		SET @sql += CHAR(13) + 'SELECT ''Updated '' + CAST(@@ROWCOUNT AS VARCHAR) + '' row(s) in ' + @MySQL + '.' + @table + ''''
	END
	ELSE IF @update = 'SQL'
	BEGIN
		SET @sql += CHAR(13) + 'EXEC UpdateTable ''' + @SQLServer + ''', ''SQL'', ''MySQL'', ''' + @table + ''', ''' + @printSQL + ''''
		SET @sql += CHAR(13) + 'SELECT ''Updated '' + CAST(@@ROWCOUNT AS VARCHAR) + '' row(s) in ' + @SQLServer + '.' + @table + ''''
	END 
	
	SET @sql += CHAR(13) + 'END'

	IF @printSQL = 'Y' EXEC PrintSQL @sql

	BEGIN TRY
		EXEC (@sql)
	END TRY
	BEGIN CATCH
		DECLARE @msg AS VARCHAR(max)
		
		SET @msg = 'Comparing table ' + @table
		EXEC ReportError @msg
		RAISERROR ('Error reported', 16, 1);
	END CATCH	
END
