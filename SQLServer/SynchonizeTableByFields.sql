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
			@mode   AS CHAR = 'C',
			@batch  AS INT  = 2)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @sql     AS NVARCHAR(max)
	DECLARE @time    AS DATETIME = CURRENT_TIMESTAMP;
	DECLARE @last    AS INT = -1
	DECLARE @count   AS INT = 0
	DECLARE @batches AS INT = 0
	DECLARE @list    AS VARCHAR(max)
	DECLARE @fields  AS VARCHAR(max) = NULL
	
	SELECT @fields = COALESCE(@fields + ',', '') + dbo.AddSelectField([Column], NULL, '', 5, 20)        FROM #TableDetails ORDER BY Id
	SELECT @list   = COALESCE(@list + ',', '')   + dbo.AddSelectField('S.' + [Column], NULL, '', 5, 20) FROM #TableDetails ORDER BY Id

	IF @mode NOT IN ('C', 'S', 'I')
	BEGIN
		SET @fields = 'Mode %s invalid. Must be C(heck), S(QL) or I(Insert)'
		RAISERROR (@fields, 16, 1, @mode)
	END
	
	IF @mode <> 'C'	
	BEGIN
		SET @sql = 'INSERT ' + @target + '.' + @table + ' (' + @fields + ') ' + CHAR(13)
		
		IF @batch IS NOT NULL SET @list = ' TOP ' + CAST(@batch AS VARCHAR) + ' ' + @list
	END
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
		WHILE (@last <> 0)
		BEGIN
			EXEC sp_executesql @sql
			SET @last   = @@ROWCOUNT
			SET @count += @last
			
			IF @batch IS NULL
				SET @last = 0
			ELSE IF @last <> 0 SET @batches += 1
		END
		
		IF @mode = 'C'
			SET @list  = 'Found ' + CAST(@count AS VARCHAR) + ' rows in table ' + @table + ' of ' +  dbo.FirstField(@source, '.', 'N') + ' not in ' + dbo.FirstField(@target, '.', 'N')
		ELSE
		BEGIN
			SET @list  = 'Copied ' + dbo.lpad(CAST(@count AS VARCHAR), 3, ' ') + ' row(s) of table ' + dbo.rpad(@table, 20, ' ') + ' from database ' + dbo.rpad(dbo.FirstField(@source, '.', 'N'), 15, ' ') + ' to ' + dbo.FirstField(@target, '.', 'N')
			
			IF @batches <> 0 AND @batches > 1 SET @list += ' in ' + CAST(@batches AS VARCHAR) + ' batches'
		END
		EXEC ReportTimeTaken @list, @time OUTPUT
	END
END
