IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UnpackEventStackById' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.UnpackEventStackById
GO

/*
 * Joins to populate @stack proved expensive. Changed to add function details using a cursor.
 */
CREATE PROCEDURE dbo.UnpackEventStackById(
                             @databaseId INT, 
                             @eventId    INT, 
                             @threshold  FLOAT, 
                             @eventTable SYSNAME,
                             @log        CHAR,
                             @error      VARCHAR(max) OUTPUT,
                             @count      INT          OUTPUT,
                             @unknown    INT          OUTPUT    )
AS
	SET NOCOUNT ON
BEGIN
	DECLARE @sql       AS VARCHAR(max)
	DECLARE @timestamp AS DATETIME
	DECLARE @xml       AS VARCHAR(max)
	DECLARE @message   AS VARCHAR(max)
	DECLARE @started   AS DATETIME
	DECLARE @timer     AS DATETIME
	DECLARE @rows      AS INT
		
	SET @eventTable = ISNULL(@eventTable, 'EVENT')
	SET @timer      = CURRENT_TIMESTAMP
		
	DECLARE @event TABLE (
				Timestamp DATETIME,
	            XML       VARCHAR(max))
	DECLARE @stack TABLE (
				[Index]          SMALLINT PRIMARY KEY,
                Depth            SMALLINT,
                Parent           SMALLINT,
                FirstChild       SMALLINT,
                LastChild        SMALLINT,
                [Left]           SMALLINT,
                [Right]          SMALLINT,
				Enter            DECIMAL(19, 3),
				Duration         DECIMAL(19, 3),
				Children         SMALLINT,
				ChildrenDuration DECIMAL(19, 3),
				Type             VARCHAR(20),
				[Function]       VARCHAR(max),
				[Schema]         SYSNAME NULL,
				Identifier       VARCHAR(255),
				Version          VARCHAR(20),
				FunctionId       INT,
				Parameters       VARCHAR(max))
	IF @threshold IS NULL SET @threshold = 0
	
	BEGIN TRY
		SET @error   = NULL	
		SET @count   = 0
		SET @unknown = 0
		
		SET @sql = 'SELECT UTCEVENTDATE, ROWDATA FROM ' + dbo.QualifyTable(@databaseId, '' + @eventTable + '') + ' WITH (NOLOCK) WHERE EventId = ' + LTRIM(STR(@eventId))
	
		INSERT INTO @event EXEC (@sql)
		SELECT  
			@timestamp = Timestamp,
			@xml       = XML 
		FROM @event	
		
		IF @xml IS NULL RETURN
		
		INSERT INTO @stack
		SELECT
			[Index],
			Depth,
			Parent,
			FirstChild,
			LastChild,
			[Left],
			[Right],
			Enter,
			Duration,
			Children,
			ChildrenDuration,
			ST.Type,
			[Function],
			CASE
				WHEN ST.Type = 'SQL' THEN PN.[Schema] 
				ELSE FM.[Schema]
			END           AS [Schema],
			CASE
				WHEN ST.Type = 'SQL' THEN PN.Identifier 
				ELSE FM.Name
			END           AS Identifier,
			CASE
				WHEN ST.Type = 'SQL' THEN PN.Version 
				ELSE FM.Version
			END           AS Version,
			CASE
				WHEN ST.Type = 'SQL' THEN FS.FunctionId 
				ELSE FM.FunctionId
			END           AS FunctionId,
			Parameters
		FROM dbo.UnpackStack(@xml) ST
		LEFT JOIN CSCFunction FM WITH (NOLOCK)
		ON  ST.[Function] = FM.Name
		AND ST.Type       = FM.Type
		AND FM.Version    IS NULL
		AND FM.[Schema]   IS NULL
		AND ST.Type       <> 'SQL'
		CROSS APPLY dbo.ParseDBName([Function], 'Y') PN
		LEFT JOIN CSCFunction FS WITH (NOLOCK)
		ON  PN.Identifier = FS.Name
		AND PN.Version    = FS.Version
		AND PN.[Schema]   = FS.[Schema]
		AND FS.Type       = 'SQL'
		WHERE Duration >= @threshold
		ORDER BY [Index]
		
		SET @count   = @@ROWCOUNT
		SET @message = 'Event ' + LTRIM(STR(@eventId)) + ' unpacked ' + LTRIM(STR(@count)) + ' stack entries'
		 		
		IF CHARINDEX(@log, 'D') <> 0 EXEC ReportTimeTaken @message, @timer OUTPUT
		
		INSERT CSCFunction(Type, [Schema], Name, Version, Stack, Discovered)
		SELECT DISTINCT
			Type,
			[Schema],
			Identifier,
			Version,
			'Y',
			@timestamp
		FROM @stack
		WHERE Identifier IS NOT NULL
		AND   FunctionId IS NULL
		
		SET @rows = @@ROWCOUNT
		
		IF @rows <> 0
		BEGIN
			SET @message = 'Event ' + LTRIM(STR(@eventId)) + ' inserted ' + LTRIM(STR(@rows)) + ' new functions'
		 		
			IF CHARINDEX(@log, 'D') <> 0 EXEC ReportTimeTaken @message, @timer OUTPUT	
			
			UPDATE ST
				SET FunctionId = FN.FunctionId
			FROM @stack ST
			LEFT JOIN CSCFunction FN WITH (NOLOCK)
			ON  ST.Type                 = FN.Type
			AND ISNULL(ST.[Schema], '') = ISNULL(FN.[Schema], '')
			AND ST.Identifier           = FN.Name
			AND ISNULL(ST.Version, '')  = ISNULL(FN.Version, '')
			WHERE ST.Identifier IS NOT NULL
			AND   ST.FunctionId IS NULL
			
			SET @rows = @@ROWCOUNT
			SET @message = 'Event ' + LTRIM(STR(@eventId)) + ' updated ' + LTRIM(STR(@rows)) + ' entries with new functions'
		 		
			IF CHARINDEX(@log, 'D') <> 0 EXEC ReportTimeTaken @message, @timer OUTPUT
		END

		INSERT INTO CSCStack (
			DatabaseId,
			EventId,
			EntryId,
			Depth,
			Parent,
			Child,
			[Left],
			[Right],
			Enter,
			Duration,
			Children,
			FunctionId,
			Parameters)
		SELECT
			@databaseId,
			@eventId,
			[Index],
			Depth,
			Parent,
			FirstChild,
			[Left],
			[Right],
			Enter,
			Duration,
			Children,
			FunctionId,
			Parameters
		FROM @stack

		SET @rows    = @@ROWCOUNT
		SET @message = 'Event ' + LTRIM(STR(@eventId)) + ' inserted ' + LTRIM(STR(@rows)) + ' new stack entries'
		 		
		IF CHARINDEX(@log, 'D') <> 0 EXEC ReportTimeTaken @message, @timer OUTPUT

		SELECT @error = Parameters FROM @stack WHERE Depth = -1
		SET @unknown = @unknown + (SELECT ISNULL(COUNT(*), 0) FROM @stack WHERE Type = 'Unknown')
	END TRY
	BEGIN CATCH
		SET @error = ERROR_MESSAGE()
		PRINT  'Event ' + LTRIM(STR(@eventId)) + ' ' + ERROR_MESSAGE() 
	END CATCH
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UnpackEventStack' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.UnpackEventStack
GO

CREATE PROCEDURE dbo.UnpackEventStack(@Database varchar(20), @eventId int, @threshold float, @print char)
AS
	SET NOCOUNT ON
BEGIN
	DECLARE @databaseId int
	DECLARE @count      int
	DECLARE @error      varchar(max)
	DECLARE @unknown    int
	
	EXEC GetdatabaseId @Database, @databaseId OUTPUT
	SET TEXTSIZE 2147483647                             
	EXEC UnpackEventStackById  @databaseId, @eventId, @threshold, @print, @error OUTPUT, @count OUTPUT, @unknown OUTPUT
END
GO