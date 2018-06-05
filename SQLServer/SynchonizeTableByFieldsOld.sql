USE BloodPressure
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SynchronizeTableByFields' AND type ='p')
BEGIN
	DROP Procedure dbo.SynchronizeTableByFields
END
GO
CREATE PROCEDURE SynchronizeTableByFields(
			@source AS sysname, 
			@target AS sysname, 
			@table  AS sysname,
			@mode   AS CHAR = 'C')
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @sql    AS NVARCHAR(max)
	DECLARE @time   AS DATETIME = CURRENT_TIMESTAMP;
	DECLARE @count  AS INT
	DECLARE @list   AS VARCHAR(max)
	DECLARE @fields AS VARCHAR(max) = NULL
	
	SELECT @fields = COALESCE(@fields + ',', '') + dbo.AddSelectField([Column], NULL, '', 5, 20)        FROM #TableDetails ORDER BY Id
	SELECT @list   = COALESCE(@list + ',', '')   + dbo.AddSelectField('S.' + [Column], NULL, '', 5, 20) FROM #TableDetails ORDER BY Id

	IF @mode NOT IN ('C', 'S', 'I')
	BEGIN
		SET @fields = 'Mode %s invalid. Must be C(heck), S(QL) or I(Insert)'
		RAISERROR (@fields, 16, 1, @mode)
	END
	
	IF @mode <> 'C'	
		SET @sql = 'INSERT ' + @target + '.' + @table + ' (' + @fields + ') ' + CHAR(13) 
	ELSE
	BEGIN
		SET @sql = ''
		SET @list = ' ''' + @target + ''' AS Target,' + @list
	END
	
	SET @sql += 'SELECT' + @list
	EXEC dbo.AddFromJoin
			@sql       OUTPUT,
			@target,
			'T',
			@source,
			'S',
			@table,
			'RIGHT JOIN',
			'AND',
			'IS NULL'
	
	IF @mode = 'S'
		PRINT @sql
	ELSE
	BEGIN
		IF @mode = 'C'
		BEGIN
			SET @fields = NULL
			SELECT @fields = COALESCE(@fields + ',', '') + [Column] FROM #TableDetails WHERE [Key] = 'Y'
			SET @sql += ' ORDER BY ' + @fields
		END
		
		EXEC sp_executesql @sql
		SET @count = @@ROWCOUNT
		
		IF @mode = 'C'
			SET @list  = 'Found ' + CAST(@count AS VARCHAR) + ' rows in table ' + @table + ' of ' +  dbo.FirstField(@source, '.', 'N') + ' not in ' + dbo.FirstField(@target, '.', 'N')
		ELSE
			SET @list  = 'Copied ' + CAST(@count AS VARCHAR) + ' row(s) of table ' + @table + ' from database ' + dbo.FirstField(@source, '.', 'N') + ' to ' + dbo.FirstField(@target, '.', 'N')
			
		EXEC ReportTimeTaken @list, @time OUTPUT
	END
END
