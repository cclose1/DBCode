
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetQuerySignature' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION GetQuerySignature
GO

CREATE FUNCTION GetQuerySignature(@query AS VARCHAR(max))
	RETURNS VARCHAR(max)
AS
BEGIN
	DECLARE @signature AS VARCHAR(max)
	DECLARE @name      AS VARCHAR(max)
	DECLARE @value     AS VARCHAR(max)

	SET @signature = ''
    DECLARE Params Cursor 
    FOR 
		SELECT Name,
		       Value 
		FROM   dbo.UnpackPairedList(@query, '&', '=')
		ORDER BY Position
	OPEN Params 

	WHILE (1 = 1)
	BEGIN
		FETCH NEXT FROM Params INTO @name, @value
		
		IF @@FETCH_STATUS <> 0 BREAK
		
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
	
			IF @char = '%' AND @index < LEN(@value)
			BEGIN
				DECLARE @converted AS CHAR
		
				SELECT @converted = Value FROM dbo.UnpackPairedList('21.!|2A.*|22."|27.''|28.(|29.)|3B.;|3A.:|40.@|26.&|3D.=|2B.+|24.$|2C.,|2F./|3F.?|25.%|23.#|5B.[|5D', '|', '.') 
				                          WHERE Name = SUBSTRING(@value, @index, 2)
				IF @converted IS NOT NULL
				BEGIN
					SET @char  = @converted
					SET @index = @index + 2
				END 
			END
			ELSE
			IF @char = '+' SET @char = ' '
			
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
		
		IF @signature <> '' SET @signature = @signature + ','
		
		IF @isText = 'N'
		BEGIN
			IF @value = '' SET @strVal = '' ELSE SET @strVal = 'N'
		END
		
		SET @signature = @signature + @name + '=' + @strVal
	END
	RETURN @signature
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'LoadWebLogRange' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE LoadWebLogRange
GO

CREATE PROCEDURE LoadWebLogRange(@databaseId  int, @first bigint OUTPUT, @maxRows int, @loaded int OUTPUT, @error int OUTPUT)
AS
	SET NOCOUNT on
BEGIN
	DECLARE @nodeId    int
	DECLARE @node      varchar(255)
	DECLARE @host      varchar(128)
	DECLARE @server    varchar(128)
	DECLARE @ip        varchar(128)
	DECLARE @timestamp varchar(50)
	DECLARE @started   datetime
	DECLARE @timer     datetime
	DECLARE @method    char
	DECLARE @seqNo     int
	DECLARE @sessSeqNo int
	DECLARE @status    int
	DECLARE @sent      int
	DECLARE @received  int
	DECLARE @duration  decimal(9, 3)
	DECLARE @sessionId varchar(500)
	DECLARE @sql       varchar(max)
	
	SET @loaded  = 0
	SET @started = CURRENT_TIMESTAMP
	SET @timer   = CURRENT_TIMESTAMP
	
	IF @maxRows IS NULL 
		SET @sql = 'SELECT '
	ELSE
		SET @sql = 'SELECT TOP ' + CAST(@maxRows AS VARCHAR) + ' '
	SET @sql     = @sql + 'Host,'                                             +
	                      'SeqNo,'                                            +
	                      'Server,'                                           +
	                      'Timestamp,'                                        +
	                      'Method,'                                           +
	                      'REPLACE(URIStem, ''+'', '' '') AS URIStem,'        +
	                      'IP,'                                               +
	                      'dbo.GetField(Cookie, ''SessionId'') AS SessionId,' +
	                      'Status,'                                           +
	                      'Sent,'                                             +
	                      'Received,'                                         +
	                      'Duration'                                          +
	               ' FROM ' + dbo.QualifyTable(@databaseId, 'WebLog') + ' WITH (NOLOCK) ' +
	               'WHERE SeqNo > ' + CAST(@first AS VARCHAR) + ' ORDER BY SeqNo'	
	
	CREATE TABLE #fids (Id  int PRIMARY KEY)
	CREATE TABLE #weblog (Host      varchar(128),
	                      SeqNo     numeric(18, 0),
	                      Server    varchar(128),
	                      Timestamp datetime,
	                      Method    varchar(10),
	                      URIStem   varchar(max),
	                      IP        varchar(64),
	                      SessionId varchar(50),
	                      Status    int,
	                      Sent      int,
	                      Received  int,
	                      Duration  int)
	INSERT INTO #weblog EXEC (@sql)
	
	EXEC ReportTimeTaken 'WebLog load', @timer OUTPUT
	DECLARE curs CURSOR LOCAL FAST_FORWARD
    FOR SELECT WL.Host,
               HST.SeqNo                  AS HostID,
               WL.SeqNo,
               WL.Server,
               SV.SeqNo                   AS ServerID,
               WL.Timestamp,
               SUBSTRING(WL.Method, 1, 1) AS Method,
               WL.URIStem                 AS Node,
               FunctionId                 AS NodeId,
               WL.SessionId,
               WL.IP,
               IP.SeqNo                   AS IPID,
               WL.Status,
               WL.Sent,
               WL.Received,
               WL.Duration / 1000.0       AS Duration
	    FROM      #weblog   WL WITH (NOLOCK) 
	    LEFT JOIN CSCFunction FN WITH (NOLOCK)
	    ON        Type = 'ASP Page'
	    AND       WL.URIStem = FN.Name
	    LEFT JOIN CSCHost HST  WITH (NOLOCK)
	    ON        WL.Host = HST.Identifier
	    LEFT JOIN CSCServer SV WITH (NOLOCK)
	    ON        WL.Server = SV.ManIP
	    LEFT JOIN CSCSourceIPs IP WITH (NOLOCK)
	    ON        WL.IP = IP.IP
	    ORDER BY WL.SeqNo
	OPEN curs
		
	WHILE 0 = 0
	BEGIN
		DECLARE @hostID   int
		DECLARE @serverID int
		DECLARE @ipID     int
		
		SET @hostID   = NULL
		SET @serverID = NULL
		SET @ipID     = NULL
		SET @nodeId   = NULL
		FETCH NEXT from curs INTO @host, 
		                          @hostID,
		                          @seqNo,
		                          @server,
		                          @serverID,
		                          @timestamp,
		                          @method,
		                          @node,
		                          @nodeId,
		                          @sessionId,
		                          @ip,
		                          @ipID,
		                          @status,
		                          @sent,
		                          @received,
		                          @duration

		IF @@fetch_status <> 0 break
		
		SET @loaded    = @loaded + 1
		SET @sessSeqNo = NULL
		
		IF @nodeId IS NULL
			EXEC GetFunctionId @timestamp, 'ASP page', @node, @nodeId OUTPUT
		ELSE IF NOT EXISTS (SELECT Id FROM #fids WHERE Id = @nodeId)
			INSERT INTO #fids VALUES (@nodeId)
			
		IF @sessionId IS NOT NULL
		BEGIN
			SELECT @sessSeqNo = SeqNo FROM CSCSession WHERE DatabaseId = @databaseId AND Id = @sessionId
			
			IF @sessSeqNo IS NULL
			BEGIN
				INSERT INTO CSCSession (DatabaseId, Id) VALUES (@databaseId, @sessionId)
				SELECT @sessSeqNo = SeqNo FROM CSCSession WHERE DatabaseId = @databaseId AND Id = @sessionId
			END
		END
		
		IF @hostID IS NULL
		BEGIN
			SELECT @hostID = SeqNo FROM CSCHost WHERE Identifier = @host
			
			IF @hostID IS NULL
			BEGIN
				INSERT INTO CSCHost (Identifier) VALUES (@host)
				SELECT @hostID = SeqNo FROM CSCHost WHERE Identifier = @host
			END
		END
		
		IF @serverID IS NULL
		BEGIN
			DECLARE @i int
		
			SET @i = CHARINDEX('\', @server)
		
			IF @i > 0 SET @server = SUBSTRING(@server, @i + 1, LEN(@server) - @i)
			
			SELECT @serverID = SeqNo FROM CSCServer WHERE ManIP = @server
			
			IF @serverID IS NULL
			BEGIN
				INSERT INTO CSCServer (ManIP) VALUES (@server)
				SELECT @serverID = SeqNo FROM CSCServer WHERE ManIP = @server
			END
		END
		
		IF @ipID IS NULL
		BEGIN
			SELECT @ipID = SeqNo FROM CSCSourceIPs WHERE IP = @ip
			
			IF @ipID IS NULL
			BEGIN
				INSERT INTO CSCSourceIPs (IP) VALUES (@ip)
				SELECT @ipID = SeqNo FROM CSCSourceIPs WHERE IP = @ip
			END
		END
		
		SET @first = @seqNo
		INSERT INTO CSCWebLog
						(databaseId,
						 SeqNo,
						 Timestamp,
						 ServerID,
						 HostID,
						 NodeId,
						 IPID,
						 SessionID,
						 Method,
						 Status,
						 Sent,
						 Received,
						 Duration) 
					VALUES
						(@databaseId,
						 @seqNo,
						 @timestamp,
						 @serverID,
						 @hostID,
						 @nodeId,
						 @ipID,
						 @sessSeqNo,
						 @method,
						 @status,
						 @sent,
						 @received,
						 @duration)
		SELECT @error = @@Error
		
		IF @error <> 0
		BEGIN
			PRINT 'Insert of ' + LTRIM(STR(@seqNo)) + ' failed with error ' + LTRIM(STR(@error))
			BREAK
		END
	END

	CLOSE curs
	EXEC ReportTimeTaken 'CSCWebLog insert', @timer OUTPUT
	UPDATE CSCFunction SET WebLog = 'Y'
	FROM CSCFunction FN	JOIN #fids ON FN.FunctionId = #fids.Id
			
	DROP TABLE #fids
	DROP TABLE #weblog

	IF @loaded = 0
		PRINT 'Starting at ' + STR(@first) + '-No web log lines found'
	ELSE
		PRINT 'Starting at ' + STR(@first) + '-Loaded '  + LTRIM(STR(@loaded)) + ' web log lines in ' + LTRIM(STR(DATEDIFF(ss, @started, CURRENT_TIMESTAMP))) + ' seconds'
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'LoadWebLog' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE LoadWebLog
GO

CREATE PROCEDURE LoadWebLog(@Database varchar(20), @batchSize int = 1000, @maxRows int = NULL)
AS
	SET NOCOUNT on
BEGIN
	DECLARE @databaseId int
	DECLARE @loaded     int
	DECLARE @first      bigint
	DECLARE @error      int
	
	SET @error = 0
	EXEC GetdatabaseId @Database, @databaseId OUTPUT
	SELECT @first = MAX(SeqNo) FROM CSCWebLog WHERE DatabaseId = @databaseId
	
	IF @first IS NULL SET @first = 0
	
	SET @loaded = -1
	
	WHILE @loaded <> 0 AND (@maxRows IS NULL OR @maxRows > 0) AND @error = 0
	BEGIN
		EXEC LoadWebLogRange @databaseId, @first OUTPUT, @batchSize, @loaded OUTPUT, @error OUTPUT
		
		IF @maxRows IS NOT NULL SET @maxRows = @maxRows - @loaded
	END
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'AnalyseWebLog' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE AnalyseWebLog
GO

CREATE PROCEDURE AnalyseWebLog(@start AS DATETIME, @end AS DATETIME = NULL)
AS
	SET NOCOUNT on
BEGIN
	DECLARE @urls TABLE(Name        VARCHAR(max),
	                    URIPath     VARCHAR(max) COLLATE SQL_Latin1_General_CP1_CS_AS,
	                    URIName     VARCHAR(max) COLLATE SQL_Latin1_General_CP1_CS_AS,
	                    First       DATETIME,
	                    Last        DATETIME,
	                    Occurrences BIGINT)
	                    
	INSERT INTO @urls
	SELECT MIN(Name),
	       URIPath,
	       URIName,
	       MIN(Timestamp) AS First,
	       MAX(Timestamp) AS Last,
	       COUNT(*)       AS Occurrences
    FROM (SELECT LOWER(dbo.GetSuffix(URIStem, '/'))                                     AS Name,
		               dbo.GetPrefix(URIStem, '/') COLLATE SQL_Latin1_General_CP1_CS_AS AS URIPath,
		               dbo.GetSuffix(URIStem, '/') COLLATE SQL_Latin1_General_CP1_CS_AS AS URIName,
		               Timestamp
		   FROM WebLog WITH (NOLOCK) WHERE Timestamp >= @start AND (@end IS NULL OR Timestamp < @end)) J1
	GROUP BY URIPath, URIName
					  
    SELECT J1.Name, U.URIPath, U.URIName, First, Last, DATEDIFF(D, First, Last) + 1 AS Days, Occurrences
        FROM (SELECT Name, Count(*) AS Count FROM @urls GROUP BY NAME) J1
        JOIN @urls U
          ON J1.Name = U.Name
       WHERE J1.Count <> 1 AND J1.Name <> ''

--   SELECT J2.Name, U.URIPath, U.URIName, First, Last, DATEDIFF(D, First, Last) + 1 AS Days, Occurrences
--        FROM (SELECT Min(Name) AS Name, Count(*) AS Count FROM @urls GROUP BY LOWER(URIPath), LOWER(URIName)) J2
--       JOIN @urls U
--          ON J2.Name = U.Name
--       WHERE J2.Count <> 1 AND J2.Name <> ''
--       ORDER BY U.URIName
END
