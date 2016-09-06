
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetURIStem' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION GetURIStem
GO

CREATE FUNCTION GetURIStem(@url AS VARCHAR(max), @maxLength AS INT)
	RETURNS VARCHAR(max)
AS
BEGIN
	IF @url = '-'
		SET @url = NULL
	ELSE IF CHARINDEX('http', @url) = 1 
	BEGIN
		DECLARE @l AS INT
		DECLARE @h AS INT
		
		-- Strip off the http../ServerName
		
		SET @l = CHARINDEX('//', @url)
		SET @l = CHARINDEX('/',  @url, @l + 3)
		
		-- Find the position of the start of the parameter string.
		
		SET @h = CHARINDEX('?',  @url)
		
		IF @h = 0 SET @h = LEN(@url) + 1

		SET @url = SUBSTRING(@url, @l, @h - @l)
		SET @url = REPLACE(@url, '%20', ' ')
	END
		SET @url = REPLACE(@url, '+', ' ')
	
	IF @maxLength <> 0 AND LEN(@url) > @maxLength SET @url = SUBSTRING(@url, 1, @maxLength)
	
	RETURN @url
END
GO

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
		FROM   dbo.UnpackPairedList(@query, '&', '=', NULL)
		ORDER BY Position
	OPEN Params 

	WHILE (1 = 1)
	BEGIN
		FETCH NEXT FROM Params INTO @name, @value
		
		IF @@FETCH_STATUS <> 0 BREAK
		
		IF @signature <> '' SET @signature = @signature + ','
		
		SET @signature = @signature + @name + '=' + dbo.Anonymize(@value, 'Y')
	END
	RETURN @signature
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'LogLongURL' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE LogLongURL
GO

CREATE PROCEDURE LogLongURL(
					@databaseId int, 
					@logSeqNo   bigint, 
					@url        varchar(max),
					@maxLength  int)
AS
	SET NOCOUNT on
BEGIN
	IF LEN(@url) >= @maxLength
	BEGIN
		DECLARE @fullURL TABLE(FileName VARCHAR(max))
		DECLARE @urlFile AS VARCHAR(max)
		DECLARE @sql     AS VARCHAR(max) = 'SELECT URIStem FROM ' + dbo.QualifyTable(@databaseId, 'WebLog') + ' WHERE SeqNo = ' + STR(@logSeqNo)

		INSERT INTO @fullURL EXEC (@sql)
		SELECT @urlFile = FileName FROM @fullURL
		
		IF @urlFile IS NOT NULL
		BEGIN
			IF EXISTS (SELECT * FROM CSCLongURL WHERE URL = @urlFile)
				UPDATE CSCLongURL
					SET Updated = CURRENT_TIMESTAMP,
						Count  += 1
				WHERE URL = @urlFile
			ELSE
				INSERT INTO CSCLongURL(FirstSeqNo, URL, Count) VALUES (@logSeqNo, @urlFile, 1)
		END
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'CreateURLHourlySummary' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE CreateURLHourlySummary
GO

CREATE PROCEDURE CreateURLHourlySummary(
					@databaseId AS SMALLINT, 
					@start      AS DATETIME, 
					@end        AS DATETIME, 
					@batchHours AS INT, 
					@count      AS INT OUTPUT,
					@log        AS CHAR = 'Y')
AS
BEGIN
	SET NOCOUNT on
	
	DECLARE @timer    AS DATETIME = CURRENT_TIMESTAMP
	DECLARE @batchEnd AS DATETIME
	DECLARE @message  AS VARCHAR(max)
	DECLARE @rowCount AS INT
	
	SET @count = 0
	
	IF @start IS NULL
	BEGIN
		SELECT @start = MAX(Timestamp) FROM CSCURLHourlySummary WHERE DatabaseId = @databaseId
		
		IF @start IS NULL 
			SELECT @start = MIN(Timestamp) FROM CSCWebLog WHERE DatabaseId = @databaseId
		ELSE
			SET @start = DATEADD(HH, 1, @start)
	END
	
	IF @start IS NULL RETURN
	
	SET @start = dbo.RoundDownTime(@start, 3600)	
	SET @end   = dbo.RoundDownTime(@end,   3600)
	
	WHILE @start < @end
	BEGIN
		SET @batchEnd = DATEADD(HH, @batchHours, @start)
		
		IF @batchEnd > @end SET @batchEnd = @end
		
		BEGIN TRY	
			INSERT CSCURLHourlySummary
			SELECT
				US.Timestamp,
				US.DatabaseId,
				US.EnvironmentId,
				US.URLId,
				US.Method,
				US.Status,
				US.ReferrerId,
				US.Count,
				US.AvgSent,
				US.AvgReceived,
				US.AvgDuration
			FROM (
				SELECT
					CAST(LTRIM(STR(Month)) + '/' + 
						 LTRIM(STR(Day))   + '/' + 
						 LTRIM(STR(Year))  + ' ' +
						 LTRIM(STR(Hour))  + ':00:00' AS DATETIME) AS Timestamp,
					DatabaseId,
					EN.EnvironmentId,
					ISNULL(NodeId, -1)            AS URLId, -- This is a precaution, should never be NULL
					Method,
					Status,
					ISNULL(ReferrerId, -1)        AS ReferrerId,
					COUNT(*)                      AS Count,
					Avg(CAST(Sent AS BIGINT))     AS AvgSent,
					Avg(CAST(Received AS BIGINT)) AS AvgReceived,
					Avg(CAST(Duration AS BIGINT)) AS AvgDuration
				FROM CSCWebLog WL
				LEFT JOIN CSCServer SV
				ON WL.ServerID = SV.SeqNo
				LEFT JOIN CSCEnvironment EN
				ON ISNULL(SV.Environment, 'Unknown') = EN.Environment
				WHERE WL.Timestamp >= @start
				AND   WL.Timestamp <  @batchEnd
				AND   WL.DatabaseId = @databaseId
				GROUP BY 
					EN.EnvironmentId,
					DatabaseId,
					Year,
					Month,
					Day,
					Hour,
					NodeId,
					Method,
					Status,
					ReferrerId) US

			SET @rowCount = @@ROWCOUNT
			SET @count   += @rowCount
			SET @message  = 'Batch starting at ' + CAST(@start AS VARCHAR(30)) + ' update of ' + LTRIM(STR(@rowCount)) + ' records'

			IF @log = 'D' EXEC ReportTimeTaken @message, @timer OUTPUT		

			SET @start = @batchEnd
		END TRY
	
		BEGIN CATCH
			DECLARE @errorNumber    AS INT
			DECLARE @errorSeverity  AS INT
			DECLARE @errorState     AS INT
			DECLARE @errorProcedure AS NVARCHAR(max)
			DECLARE @errorLine      AS INT
			DECLARE @errorMessage   AS NVARCHAR(max)
			DECLARE @tStart         AS VARCHAR(30) = CAST(@start AS VARCHAR(30))
			
			SELECT
				@errorNumber    = ERROR_NUMBER(),
				@errorSeverity  = ERROR_SEVERITY(),
				@errorState     = ERROR_STATE(),
				@errorProcedure = ERROR_PROCEDURE(),
				@errorLine      = ERROR_LINE(),
				@errorMessage   = ERROR_MESSAGE()
				
				RAISERROR(
					'In batch starting %s error %i in %s(%i) %s',
					@errorSeverity,
					@errorState, 
					@tStart,
					@errorNumber,
					@errorProcedure,
					@errorLine,
					@errorMessage)
				RETURN
		END CATCH
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'SetURLGap' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE SetURLGap
GO

CREATE PROCEDURE SetURLGap(
					@databaseId  INT, 
					@sessionId   INT,
					@log         CHAR = 'N',
					@totalURLs   INT      OUTPUT,
					@gapURLs     INT      OUTPUT,
					@start       DATETIME OUTPUT,
					@elapsed     FLOAT    OUTPUT)
AS
	SET NOCOUNT on
BEGIN
	DECLARE @end          AS DATETIME
	DECLARE @serverId     AS INT
	DECLARE @hostId       AS INT
	DECLARE @seqNo        AS BIGINT
	DECLARE @bSeqNo       AS BIGINT
	DECLARE @duration     AS BIGINT
	DECLARE @sent         AS INT
	DECLARE @received     AS BIGINT
	DECLARE @gStart       AS DATETIME
	DECLARE @sStart       AS DATETIME
	DECLARE @sEnd         AS DATETIME
	DECLARE @tSent        AS BIGINT
	DECLARE @tReceived    AS BIGINT
	DECLARE @tDuration    AS BIGINT
	DECLARE @timer        AS DATETIME = CURRENT_TIMESTAMP
	DECLARE @message      AS VARCHAR(max)
	DECLARE @startDynamic AS CHAR
	DECLARE @isDynamic    AS CHAR

	SET @totalURLs = 0
	SET @gapURLs   = 0
	
	DECLARE setGap CURSOR LOCAL FAST_FORWARD 
	FOR SELECT
			Timestamp                        AS URLStart,
			DATEADD(MS, Duration, Timestamp) AS URLEnd,
			ServerId,
			HostId,
			SeqNo,
			Sent,
			Received,
			Duration,
			CASE WHEN URLType IN ('aspx', 'axd', 'xslt') THEN 'Y' ELSE 'N' END AS IsDynamic
	    FROM CSCWebLog   WL
	    JOIN CSCFunction FN
	    ON WL.NodeId = FN.FunctionId
	    WHERE DatabaseId = @databaseId
	    AND   SessionId  = @sessionId
	    ORDER BY Timestamp, Duration DESC
	OPEN setGap 
	
	IF @log = 'D' EXEC ReportTimeTaken 'Load session URLs from CSCWebLog', @timer OUTPUT
	
	WHILE 0 = 0
	BEGIN		
		FETCH NEXT from setGap INTO @start, @end, @serverId, @hostId, @seqNo, @sent, @received, @duration, @isDynamic

		IF @@fetch_status <> 0
		BEGIN
			IF @totalURLs <> 0
			BEGIN
				SET @message   = 'Updating session ' + LTRIM(STR(@sessionID)) + ' for ' + LTRIM(STR(@totalURLs)) + ' URLs'
				UPDATE CSCSession
					SET [End]         = @sEnd,
						Start         = @sStart,
						FirstServerId = @serverId,
						FirstHostId   = @hostId,
						URLs          = @totalURLs,
						Sent          = @tSent,
						Received      = @tReceived,
						URLDuration   = @tDuration
				WHERE DatabaseId = @databaseId
				AND   SeqNo      = @sessionId
				
				IF @log = 'D' EXEC ReportTimeTaken @message, @timer OUTPUT
			END
			
			BREAK
		END
		
		IF @totalURLs = 0 
		BEGIN
			SET @sStart       = @start
			SET @gStart       = @start
			SET @tSent        = @sent
			SET @tReceived    = @received
			SET @tDuration    = @duration
			SET @bSeqNo       = @seqNo
			SET @startDynamic = @isDynamic
		END
		
		SET @totalURLs += 1
		SET @tSent     += @sent
		SET @tReceived += @received
		SET @tDuration += @duration
		
		IF @start > @sEnd
		BEGIN
			SET @gapURLs += 1
			UPDATE CSCWebLog 
				SET MergeDuration = DATEDIFF(ms, Timestamp, @sEnd) 
			WHERE DatabaseId = @databaseId
			AND   SeqNo = @bSeqNo
			UPDATE CSCWebLog 
				SET Gap           = DATEDIFF(ms, @sEnd, @start),
					MergeDuration = @duration
			WHERE DatabaseId = @databaseId
			AND   SeqNo = @seqNo
			
			SET @bSeqNo       = @seqNo
			SET @startDynamic = @isDynamic
			SET @gStart       = @start
			
			IF @log = 'D' 
			BEGIN
				SET @message = 'Session ' + LTRIM(STR(@sessionID)) + ' updated URL ' + LTRIM(STR(@seqNo))
				
				IF @log = 'D' EXEC ReportTimeTaken @message, @timer OUTPUT
			END
		END	
		
		IF @gStart = @start AND @isDynamic = 'Y' AND @startDynamic ='N'
		BEGIN
			SET @bSeqNo       = @seqNo
			SET @startDynamic = 'Y'
		END
		
		IF @sEnd IS NULL OR @end > @sEnd SET @sEnd = @end
	END
	
	SET @elapsed = CAST(@tDuration / 1000.0 AS FLOAT)
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UpdateSessionDetails' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE UpdateSessionDetails
GO

CREATE PROCEDURE UpdateSessionDetails(
					@database   VARCHAR(20), 
					@first      INT, 
					@last       INT,
					@maxTxnUrls INT  = 10000,
					@nullStart  CHAR = 'Y',
					@log        CHAR = 'Y')
AS
	SET NOCOUNT on
BEGIN
	DECLARE @databaseId AS INT
	DECLARE @sid        AS INT
	DECLARE @timer1     AS DATETIME = CURRENT_TIMESTAMP
	DECLARE @timer2     AS DATETIME
	DECLARE @timer3     AS DATETIME
	DECLARE @sessions   AS INT = 0
	DECLARE @tSessions  AS INT = 0
	DECLARE @txnURLS    AS INT = 0
	DECLARE @tURLS      AS INT = 0 
	DECLARE @txnGaps    AS INT = 0
	DECLARE @uURLS      AS INT = 0
	DECLARE @elapsed    AS FLOAT
	DECLARE @start      AS DATETIME
	DECLARE @message    AS VARCHAR(max)
	DECLARE @logLoad    AS CHAR = 'N'
	DECLARE @pSid       AS INT
	
	EXEC GetdatabaseId @Database, @databaseId OUTPUT
	
	IF @databaseId IS NULL RETURN
	
	IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCSessionLoad') AND OBJECTPROPERTY(id, N'IsUserTable') = 1) SET @logLoad = 'Y'

	IF @first IS NULL AND @logLoad = 'Y' SELECT @first = First, @last = Last FROM CSCSessionLoad
	IF @first IS NULL SET @first = 1
	IF @last  IS NULL SELECT @last = MAX(SeqNo) FROM CSCSession
	
	SET @pSid = @first
		
	DECLARE sessions CURSOR LOCAL FAST_FORWARD 
	FOR 
	SELECT SeqNo
	    FROM CSCSession
	    WHERE SeqNo >= @first
	    AND   SeqNo <= @last
	    AND   Id    <> ''
	    AND  (Start IS NULL OR @nullStart = 'N')
	    ORDER BY SeqNo
	OPEN sessions 
	
	IF @log IN ('D', 'S') EXEC ReportTimeTaken 'Load sessions from CSCWebLog', @timer1 OUTPUT
	
	SET @timer2 = CURRENT_TIMESTAMP
	SET @timer3 = CURRENT_TIMESTAMP
	
	WHILE 0 = 0
	BEGIN
		DECLARE @urlTot AS INT
		DECLARE @urlUpd AS INT
		
		FETCH NEXT from sessions INTO @sid
		
		IF @maxTxnUrls IS NOT NULL AND (@@fetch_status <> 0 AND @txnURLS <> 0 OR @txnURLS > @maxTxnUrls)
		BEGIN
			DECLARE @history AS CHAR
			
			IF @logLoad = 'Y' 
			BEGIN
				UPDATE CSCSessionLoad 
				SET First    = @sid,
					Start    = @start,
					Updated  = CURRENT_TIMESTAMP,
					Sessions = @tSessions,
					Urls     = @txnURLS,
					Gaps     = @txnGaps,
					Duration = dbo.GetTimeDiff(@timer3, CURRENT_TIMESTAMP)

				SELECT @history = History FROM CSCSessionLoad
				
				IF @history = 'Y'
					INSERT CSCSessionLoadHistory
					VALUES (
						CURRENT_TIMESTAMP,
						@pSid, 
						@start, 
						@tSessions, 
						@txnURLS, 
						@txnGaps, 
						dbo.GetTimeDiff(@timer3, CURRENT_TIMESTAMP))
			END
				
			COMMIT
			SET @pSid = @sid
			
			IF @log IN ('D', 'S')
			BEGIN
				SET @message = 'Transaction sessions '   + LTRIM(STR(@tSessions)) + 
							   ' urls '                  + LTRIM(STR(@txnURLS))
				EXEC ReportTimeTaken @message, @timer3 OUTPUT
			END

			SET @timer3    = CURRENT_TIMESTAMP
			SET @txnURLS   = 0
			SET @txnGaps   = 0
			SET @tSessions = 0
		END
		
		IF @@fetch_status <> 0 BREAK

		IF @maxTxnUrls IS NOT NULL AND @txnURLS = 0 BEGIN TRANSACTION
			
		EXEC SetURLGap @databaseId, @sid, @log, @urlTot OUTPUT, @urlUpd OUTPUT, @start OUTPUT, @elapsed OUTPUT
		SET @txnURLS   += @urlTot
		SET @txnGaps   += @urlUpd
		SET @sessions  += 1
		SET @tSessions += 1
		SET @tURLS     += @urlTot
		SET @uURLS     += @urlUpd
				
		IF @log IN ('D', 'S')
		BEGIN
			SET @message = 'Session '   + LTRIM(STR(@sid)) + 
						   ' start '    + dbo.FormatDate(@start, 'dd-MMM-yy HH:MI:ss') +
						   ' duration ' + LTRIM(STR(@elapsed)) + 
						   ' has '      + LTRIM(STR(@urlTot)) + ' urls and ' + LTRIM(STR(@urlUpd)) + ' gaps'
			EXEC ReportTimeTaken @message, @timer2 OUTPUT
		END
	END
	
	SET @message = 'Total URLS ' + LTRIM(STR(@tUrls)) + ' gap updates ' + LTRIM(STR(@uUrls)) + ' in ' + LTRIM(STR(@sessions)) + ' sessions'
	
	IF @log <> 'N' EXEC ReportTimeTaken @message, @timer1 OUTPUT
END 
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'LoadWebLogRange' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE LoadWebLogRange
GO

CREATE PROCEDURE LoadWebLogRange(
					@databaseId  INT, 
					@first       BIGINT OUTPUT, 
					@maxRows     INT,
					@loaded      INT OUTPUT, 
					@error       INT OUTPUT,
					@earliestURL DATETIME OUTPUT,
					@minSession  INT OUTPUT,
					@maxSession  INT OUTPUT,
					@log         CHAR = 'Y')
AS
	SET NOCOUNT on
BEGIN
	DECLARE @timestamp    DATETIME
	DECLARE @started      DATETIME
	DECLARE @timer        DATETIME
	DECLARE @seqNo        BIGINT
	DECLARE @sql          VARCHAR(max)
	DECLARE @select       VARCHAR(max)
	DECLARE @maxURLLen    INT = 255
	DECLARE @lSid         INT
	DECLARE @hSid         INT
	DECLARE @serverChange CHAR
	
	SET @loaded  = 0
	SET @started = CURRENT_TIMESTAMP
	SET @timer   = CURRENT_TIMESTAMP
	
	IF @maxRows IS NULL 
		SET @select = 'SELECT '
	ELSE
		SET @select = 'SELECT TOP ' + CAST(@maxRows AS VARCHAR) + ' '
	
	SET @sql     = 'SELECT Host,
                           HST.SeqNo                           AS HostID,
	                       WL.SeqNo,
	                       Server, 
	                       SV.SeqNo                            AS ServerID,
	                       Timestamp,
	                       Date,
	                       Method,
	                       WL.Node, 
	                       FN.FunctionId                       AS NodeId,
	                       Referrer,
	                       RF.FunctionId                       AS ReferrerId,
	                       WL.IP, 
	                       IP.SeqNo                            AS IPID,
	                       WL.UserAgent,
	                       UA.SeqNo                            AS UserAgentId,
	                       SessionId,
	                       NULL                                AS SessionSeqNo,
	                       Status,
	                       Sent,
	                       Received,
	                       Duration
	                FROM (' + @select + '
								Host, 
								SeqNo, 
								Server,
								Timestamp,
								CAST(Timestamp AS Date)                          AS Date,
								SUBSTRING(Method, 1, 1)                          AS Method, 
			                    dbo.GetURIStem(URIStem, ' + STR(@maxURLLen) + ') AS Node,
	                            dbo.GetURIStem(Referrer, 0)                      AS Referrer,
								IP,
								UserAgent,
								dbo.GetField(Cookie, ''NET_SessionId'')          AS SessionId,
								Status,
								Sent,
								Received,
								Duration
						   FROM ' + dbo.QualifyTable(@databaseId, 'WebLog') + ' WITH (NOLOCK)
						   WHERE SeqNo > ' + CAST(@first AS VARCHAR) + '
						   ORDER BY SeqNo) WL
	                LEFT JOIN CSCFunction FN WITH (NOLOCK) 
	                ON        FN.Type = ''ASP Page''
	                AND       FN.Name = WL.Node
	                LEFT JOIN CSCFunction RF WITH (NOLOCK) 
	                ON        RF.Type = ''ASP Page''
	                AND       RF.Name = Referrer
	                LEFT JOIN CSCHost HST  WITH (NOLOCK) 
	                ON        WL.Host = HST.Identifier 
	                LEFT JOIN CSCServer SV WITH (NOLOCK) 
	                ON        WL.Server = SV.ManIP 
	                AND      (WL.Timestamp >= SV.Deployed AND 
	                          SV.Deployed IS NOT NULL     AND
	                          WL.Timestamp <  ISNULL(SV.Removed, ''01-Jan-9999'') OR
	                          SV.Deployed IS NULL)
	                LEFT JOIN CSCSourceIPs IP WITH (NOLOCK) 
	                ON        WL.IP = IP.IP
	                LEFT JOIN CSCUserAgent UA WITH (NOLOCK) 
	                ON        WL.UserAgent = UA.Name'
	           
	CREATE TABLE #weblog (Host         VARCHAR(128),
	                      HostId       INT,
	                      SeqNo        NUMERIC(18, 0) PRIMARY KEY,
	                      Server       VARCHAR(128),
	                      ServerId     INT,
	                      Timestamp    DATETIME,
	                      Date         DATE,
	                      Method       CHAR(1),
	                      Node         VARCHAR(max),
	                      NodeId       INT,
	                      Referrer     VARCHAR(max),
	                      ReferrerId   INT,
	                      IP           VARCHAR(64),
	                      IPID         INT,
	                      UserAgent    VARCHAR(1000),
	                      UserAgentId  SMALLINT,
	                      SessionId    VARCHAR(50),
	                      SessionSeqNo INT,
	                      Status       INT,
	                      Sent         INT,
	                      Received     INT,
	                      Duration     INT)
	
	INSERT INTO #weblog EXEC (@sql)
	
	IF @log = 'D' EXEC ReportTimeTaken 'WebLog load', @timer OUTPUT
	
	SET @serverChange = 'N'
	UPDATE SV
		SET Deployed = WL.Deployed
	FROM (
		SELECT
			Server,
			MIN(Timestamp) AS Deployed
		FROM #weblog
		GROUP BY Server) WL
	JOIN CSCServer SV
	ON  WL.Server   = SV.ManIp
	AND SV.Deployed IS NULL
	
	IF @@ROWCOUNT <> 0 SET @serverChange = 'Y'
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCServer Deployed', @timer OUTPUT
	
	INSERT INTO CSCServer(Name, ManIP, Deployed, Environment)
	SELECT 
		WL.Server, 
		WL.Server, 
		Min(WL.Timestamp),
		'Unknown'
	FROM #weblog WL
	LEFT JOIN CSCServer SV
	ON   WL.Server = SV.ManIP
	AND  WL.Timestamp >= SV.Deployed
	AND (WL.Timestamp <  SV.Removed OR SV.Removed IS NULL)
	WHERE WL.ServerId IS NULL
	GROUP BY Server
	
	IF @serverChange = 'Y' OR @@ROWCOUNT <> 0
	BEGIN
		DECLARE @prevSeqNo AS INT
		/* 
		 * This is only necessary if for a server the log SeqNo is not in the same order as tho log
		 * timestamp. Make sure the Deployed and Removed ranges don't overlap
		 */
		DECLARE svrUPD CURSOR LOCAL FAST_FORWARD 
		FOR SELECT 
			SeqNo,
			Deployed,
			ROW_NUMBER() OVER (PARTITION BY Name ORDER BY Deployed) AS Row
	    FROM CSCServer
	    WHERE Deployed IS NOT NULL

		OPEN svrUPD
	
		WHILE 0 = 0
		BEGIN
			DECLARE @svrNo    AS INT
			DECLARE @deployed AS DATETIME
			DECLARE @rowNo    AS INT
		
			FETCH NEXT from svrUPD INTO @svrNo, @deployed, @rowNo

			IF @@fetch_status <> 0 BREAK
			
			IF @rowNo <> 1 
				UPDATE CSCServer
					SET Removed = @deployed
				WHERE SeqNo = @prevSeqNo
			
			SET @prevSeqNo = @svrNo
		END
	END
	
	UPDATE #weblog
	SET ServerId = SV.SeqNo
	FROM #weblog WL
	JOIN CSCServer SV
	ON   WL.Server = SV.ManIP
	AND  WL.Timestamp >= SV.Deployed
	AND (WL.Timestamp <  SV.Removed OR SV.Removed IS NULL)
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCServers', @timer OUTPUT
	
	INSERT INTO CSCHost(Identifier, Discovered)
	SELECT Host, MIN(WL.Timestamp)
	FROM #weblog WL
	WHERE WL.HostId IS NULL
	GROUP BY WL.Host
	
	UPDATE #weblog
	SET HostID = CSCHost.SeqNo
	FROM #weblog WL
	JOIN CSCHost
	ON  WL.Host  = CSCHost.Identifier
	WHERE WL.HostId IS NULL	
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCHost', @timer OUTPUT
	
	INSERT INTO CSCUserAgent(Name, Discovered)
	SELECT UserAgent, MIN(WL.Timestamp)
	FROM #weblog WL
	WHERE WL.UserAgentId IS NULL
	AND   WL.UserAgent   IS NOT NULL
	AND   WL.UserAgent   <> '-'
	GROUP BY WL.UserAgent
	
	UPDATE #weblog
	SET UserAgentId = CSCUserAgent.SeqNo
	FROM #weblog WL
	JOIN CSCUserAgent
	ON  WL.UserAgent  = CSCUserAgent.Name
	WHERE WL.UserAgentId IS NULL
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCUserAgent', @timer OUTPUT
	
	INSERT INTO CSCSession(DatabaseId, Id) 
	SELECT @databaseId, SessionId
	FROM (SELECT 
			SessionId
		  FROM #weblog
		  GROUP BY SessionId) WL
	LEFT JOIN CSCSession SS
	ON  WL.SessionId = SS.Id
	AND SS.DatabaseId = @databaseId
	WHERE SS.Id IS NULL
	AND   WL.SessionId IS NOT NULL
	AND   LTRIM(WL.SessionId) <> ''
	
	UPDATE #weblog
		SET SessionSeqNo = SS.SeqNo
	FROM #weblog WL
	JOIN CSCSession SS
	ON  WL.SessionId  = SS.Id
	AND SS.DatabaseId = @databaseId
	WHERE WL.SessionSeqNo IS NULL
	
	IF @log = 'D' EXEC ReportTimeTaken 'Create CSCSessions', @timer OUTPUT
		
	INSERT INTO CSCSourceIPs(IP, Discovered)
	SELECT WL.IP, MIN(WL.Timestamp)
	FROM #weblog WL
	WHERE WL.IPId IS NULL
	GROUP BY WL.IP
	
	UPDATE #weblog
	SET IPId = CSCSourceIPs.SeqNo
	FROM #weblog WL
	JOIN CSCSourceIPs
	ON  WL.IP  = CSCSourceIPs.IP
	WHERE WL.IPId IS NULL
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCSourceIPs', @timer OUTPUT
	
	INSERT INTO CSCServerUpdate(DatabaseId, ServerId, Date, URLs, SessionURLs)
	SELECT 
		@databaseId,
		WL.ServerId,
		WL.Date,
		0,
		0
	FROM (SELECT DISTINCT Date, ServerId FROM #weblog) WL
	LEFT JOIN CSCServerUpdate SU
	ON  WL.Date       = SU.Date
	AND WL.ServerId   = SU.ServerId
	AND SU.DatabaseId = @databaseId
	WHERE SU.ServerId IS NULL
	
	UPDATE SU
		SET Updated      = CURRENT_TIMESTAMP,
			Updates     += 1,
			URLS        += B.URLs,
			SessionURls += B.SessionURLs
	FROM CSCServerUpdate SU WITH (NOLOCK)
	JOIN (SELECT 
			Date,
			ServerId,
			COUNT(*)         AS URLs,
			SUM(HasSession)  AS SessionURLs
		  FROM (SELECT 
					Date, 
					ServerId, 
					CASE WHEN SessionId IS NULL OR SessionId = '' THEN 0 ELSE 1 END AS HasSession
				FROM #weblog) A
		  GROUP BY Date, ServerId) B
	ON  SU.Date       = B.Date
	AND SU.ServerId   = B.ServerId
	AND SU.DatabaseId = @databaseId
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCServerUpdate', @timer OUTPUT
	
	INSERT INTO CSCFunction(Name, Type, Discovered)
	SELECT WL.Node, 'ASP page', MIN(WL.Timestamp)
	FROM #weblog WL
	WHERE WL.NodeId IS NULL
	GROUP BY WL.Node
	
	UPDATE #weblog
	SET NodeId = FN.FunctionId
	FROM #weblog WL
	JOIN CSCFunction FN
	ON  WL.Node = FN.Name
	AND FN.Type = 'ASP page'
	WHERE WL.NodeId IS NULL		
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCFunction - Node', @timer OUTPUT
	
	-- This should only be necessary if the referred to URL was first encountered in this
	-- batch as a Node URL.
		
	UPDATE #weblog                     
	SET ReferrerId = FN.FunctionId 
	FROM #weblog WL
	JOIN CSCFunction FN
	ON  Referrer = FN.Name
	AND FN.Type  = 'ASP page'
	WHERE WL.ReferrerId  IS NULL
	AND   Referrer       IS NOT NULL		                     

	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCFunction - Referrer Update', @timer OUTPUT
	
	-- The following is a precautionary measure as by this stage all referred to URLs should either have occurred as
	-- a node in an earlier batch or this one.
	
	INSERT INTO CSCFunction(Name, Type, Discovered)
	SELECT Referrer, 'ASP page', MIN(WL.Timestamp)
	FROM #weblog WL
	WHERE WL.ReferrerId IS NULL
	AND   Referrer      IS NOT NULL
	GROUP BY Referrer
	
	UPDATE #weblog                     
	SET ReferrerId = FN.FunctionId 
	FROM #weblog WL
	JOIN CSCFunction FN
	ON  Referrer = FN.Name
	AND FN.Type  = 'ASP page'
	WHERE WL.ReferrerId  IS NULL
	AND   Referrer       IS NOT NULL	
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCFunction - Referrer Insert', @timer OUTPUT

	DECLARE longURL CURSOR LOCAL FAST_FORWARD 
	FOR SELECT 
			SeqNo,
			Node
	    FROM #weblog WL
	    WHERE LEN(Node) >= @maxURLLen
	OPEN longUrl
	
	WHILE 0 = 0
	BEGIN
		DECLARE @url    AS VARCHAR(max)
		
		FETCH NEXT from longURL INTO @seqNo, @url

		IF @@fetch_status <> 0 BREAK

		EXEC LogLongURL @databaseId, @seqNo, @url, @maxURLLen
	END
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update CSCLongURL', @timer OUTPUT
	
	INSERT INTO CSCWebLog(
					DatabaseId,
					SeqNo,
					Timestamp,
					ServerID,
					HostID,
					NodeId,
					ReferrerId,
					IPID,
					UserAgentId,
					SessionId,
					Method,
					Status,
					Sent,
					Received,
					Duration)
	SELECT @databaseId,
	       SeqNo, 
	       Timestamp,
	       ServerID,					
	       HostID,
	       NodeId,
	       ReferrerId,
	       IPID,
	       UserAgentId,
	       SessionSeqNo,
	       Method,
	       Status,
	       Sent,
	       Received,
	       Duration
	FROM #weblog
		
	IF @log = 'D' EXEC ReportTimeTaken 'CSCWebLog insert', @timer OUTPUT
	
	UPDATE CSCSession
		SET Start = NULL
	FROM (
		SELECT DISTINCT SessionSeqNo 
		FROM #weblog
		WHERE SessionId <> '') WL
	JOIN CSCSession SS
	ON   SS.DatabaseId   = @databaseId
	AND  WL.SessionSeqNo = SS.SeqNo
	
	IF @log = 'D' EXEC ReportTimeTaken 'CSCSession clear Start', @timer OUTPUT
	
	SELECT @error = @@Error 
	
	IF @error <> 0 PRINT 'Insert of ' + LTRIM(STR(@seqNo)) + ' failed with error ' + LTRIM(STR(@error))
	
	SELECT @loaded = COUNT(*) FROM #weblog

	IF @log = 'D' OR @log = 'B'
	BEGIN
		IF @loaded = 0
			PRINT 'Starting at ' + LTRIM(STR(@first)) + '-No web log lines found'
		ELSE
			PRINT 'Starting at ' + LTRIM(STR(@first)) + '-Loaded '  + LTRIM(STR(@loaded)) + ' web log lines in ' + LTRIM(STR(DATEDIFF(ss, @started, CURRENT_TIMESTAMP))) + ' seconds'
	END
	
	SELECT @lSid = MIN(SessionSeqNo), @hSid = MAX(SessionSeqNo)
	FROM #weblog 
	WHERE SessionSeqNo IS NOT NULL
	AND   SessionId    <> ''
	
	IF @minSession IS NULL OR @lSid < @minSession SET @minSession = @lSid
	IF @maxSession IS NULL OR @hSid > @maxSession SET @maxSession = @hSid
	
	SELECT @first     = ISNULL(Max(SeqNo),     @first)       FROM #weblog
	SELECT @timestamp = ISNULL(Min(Timestamp), @earliestURL) FROM #weblog
	
	IF @earliestURL IS NULL OR @timestamp < @earliestURL SET @earliestURL = @timestamp
			
	DROP TABLE #weblog
END
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'LoadWebLog' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE LoadWebLog
GO

CREATE PROCEDURE LoadWebLog(
					@database      VARCHAR(20), 
					@batchSize     INT  = 1000, 
					@maxRows       INT  = NULL,
					@createSummary CHAR = 'Y',
					@updateGaps    CHAR = 'Y',
					@log           CHAR = 'S')
AS
	SET NOCOUNT on
BEGIN
	DECLARE @databaseId  AS INT
	DECLARE @loaded      AS INT
	DECLARE @first       AS BIGINT
	DECLARE @next        AS BIGINT
	DECLARE @error       AS INT
	DECLARE @started     AS DATETIME = CURRENT_TIMESTAMP
	DECLARE @sRows       AS BIGINT
	DECLARE @sReserved   AS BIGINT
	DECLARE @sDataSize   AS BIGINT
	DECLARE @sIndexSize  AS BIGINT
	DECLARE @sUnused     AS BIGINT
	DECLARE @earliestURL AS DATETIME = NULL
	DECLARE @eRows       AS BIGINT
	DECLARE @eReserved   AS BIGINT
	DECLARE @eDataSize   AS BIGINT
	DECLARE @eIndexSize  AS BIGINT
	DECLARE @eUnused     AS BIGINT
	DECLARE @dataAdded   AS FLOAT
	DECLARE @indexAdded  AS FLOAT
	DECLARE @message     AS VARCHAR(max)
	DECLARE @minSession  AS INT
	DECLARE @maxSession  AS INT
	
	EXEC GetTableStatistics CSCWebLog,
					        @sRows      OUTPUT,
					        @sReserved  OUTPUT,
					        @sDataSize  OUTPUT,
					        @sIndexSize OUTPUT,
						    @sUnused    OUTPUT
	SET @error = 0
	EXEC GetdatabaseId @Database, @databaseId OUTPUT
	
	IF @databaseId IS NULL RETURN
	
	SELECT 
		@first       = ISNULL(MAX(SeqNo), 1),
		@earliestURL = ISNULL(MAX(Timestamp), '01-Jan-1900')
	FROM CSCWebLog 
	WHERE DatabaseId = @databaseId
	
	EXEC ReportTimeTaken 'Get start sequence', @started OUTPUT
	
	IF @first IS NULL SET @first = 0
	
	SET @loaded = -1
	SET @next   = @first
	
	WHILE @loaded <> 0 AND (@maxRows IS NULL OR @maxRows > 0) AND @error = 0
	BEGIN
		BEGIN TRY
			EXEC LoadWebLogRange  
					@databaseId, 
					@next        OUTPUT, 
					@batchSize, 
					@loaded      OUTPUT, 
					@error       OUTPUT, 
					@earliestURL OUTPUT, 
					@minSession  OUTPUT,
					@maxSession  OUTPUT,
					@log
		END TRY
		BEGIN CATCH
			DECLARE @errorNumber    AS INT
			DECLARE @errorSeverity  AS INT
			DECLARE @errorState     AS INT
			DECLARE @errorProcedure AS NVARCHAR(max)
			DECLARE @errorLine      AS INT
			DECLARE @errorMessage   AS NVARCHAR(max)
			DECLARE @start          AS VARCHAR(30) = LTRIM(STR(@first, 30))
			
			SELECT
				@errorNumber    = ERROR_NUMBER(),
				@errorSeverity  = ERROR_SEVERITY(),
				@errorState     = ERROR_STATE(),
				@errorProcedure = ERROR_PROCEDURE(),
				@errorLine      = ERROR_LINE(),
				@errorMessage   = ERROR_MESSAGE()
				
				RAISERROR(
					'In batch starting %s error %i in %s(%i) %s', 
					@errorSeverity, 
					@errorState,
					@start,
					@errorNumber,
					@errorProcedure,
					@errorLine,
					@errorMessage)
				RETURN
		END CATCH
		
		IF @maxRows IS NOT NULL SET @maxRows = @maxRows - @loaded
	END
		
	IF @log <> 'N'
	BEGIN
		SET @message = 'Starting at ' + LTRIM(STR(@first))
		
		IF @next <= @first
			PRINT @message + ' no new URLS found'
		ELSE
		BEGIN
			EXEC GetTableStatistics CSCWebLog,
							        @eRows      OUTPUT,
							        @eReserved  OUTPUT,
								    @eDataSize  OUTPUT,
									@eIndexSize OUTPUT,
									@eUnused    OUTPUT
			SET @dataAdded =  CAST(@eDataSize  - @sDataSize  AS FLOAT) / 1000000
			SET @indexAdded = CAST(@eIndexSize - @sIndexSize AS FLOAT) / 1000000
			SET @message    = 'Load of ' + LTRIM(STR(@next - @first))+ ' URLS minumum session ' + 
							LTRIM((STR(@minSession))) + ' maximum session ' + LTRIM((STR(@maxSession))) + ' added ' + 
						    LTRIM((STR(@dataAdded, 10, 3))) + ' MB to data, ' + LTRIM((STR(@indexAdded, 10, 3))) + ' MB to index and'
			EXEC ReportTimeTaken @message, @started OUTPUT
			
			SET @sRows      = @eRows
			SET @sReserved  = @eReserved
			SET @sDataSize  = @eDataSize
			SET @sIndexSize = @eIndexSize
			SET @sUnused    = @eUnused
		END
	END
	
	IF @createSummary = 'Y' AND @earliestURL IS NOT NULL
	BEGIN
		DECLARE @end   AS DATETIME
		DECLARE @count AS INT
		DECLARE @rows  AS BIGINT

		SET @earliestURL = dbo.RoundDownTime(@earliestURL, 3600)
		
		DELETE CSCURLHourlySummary 
		WHERE DatabaseId = @databaseId AND Timestamp >= @earliestURL
		
		SET @rows =  @@ROWCOUNT
		
		IF @log <> 'N' AND @rows <> 0
		BEGIN
			SET @message = 'Deletion of ' + LTRIM(STR(@rows)) + ' rows from CSCURLHourlySummary'
			EXEC ReportTimeTaken @message, @started OUTPUT
		END
		
		SELECT @end = MAX(Timestamp) FROM CSCWebLog WHERE DatabaseId = @databaseId
		EXEC CreateURLHourlySummary @databaseId, @earliestURL, @end, 1, @count OUTPUT, @log
		
		IF @log <> 'N'
		BEGIN
			EXEC GetTableStatistics CSCWebLog,
							        @eRows      OUTPUT,
							        @eReserved  OUTPUT,
								    @eDataSize  OUTPUT,
									@eIndexSize OUTPUT,
									@eUnused    OUTPUT
			SET @dataAdded  = CAST(@eDataSize  - @sDataSize  AS FLOAT) / 1000000
			SET @indexAdded = CAST(@eIndexSize - @sIndexSize AS FLOAT) / 1000000
			SET @message    = 'Creation of ' + LTRIM(STR(@count))+ ' URL summary records added ' + 
						      LTRIM((STR(@dataAdded, 10, 3))) + ' MB to data, ' + LTRIM((STR(@indexAdded, 10, 3))) + ' MB to index and'
			EXEC ReportTimeTaken @message, @started OUTPUT
		END
	END
	
	IF @updateGaps = 'Y' EXEC UpdateSessionDetails @database, @minSession, @maxSession, @nullStart = 'Y', @log = @log
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
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.IntervalRange') and OBJECTPROPERTY(id, N'IsTableFunction') = 1)
	DROP FUNCTION dbo.IntervalRange
GO

CREATE FUNCTION dbo.IntervalRange(@start AS DATETIME, @end AS DATETIME = NULL, @interval AS INT = NULL)
	RETURNS @range TABLE (
				Start    DATETIME,
				[End]    DATETIME,
				Interval INT,
				Year     AS Year(Start),
				Month    AS Month(Start),
				Day      AS Day(Start),
				Hour     AS DATEPART(HH, Start),
				Minute   AS DATEPART(MI, Start))
AS
BEGIN
	IF @interval IS NULL OR @interval < 1 SET @interval = 300
	IF @start IS NULL SET @start = '01-Jan-1900'
	IF @end   IS NULL SET @end   = CURRENT_TIMESTAMP
	
	SET @start = dbo.RoundDownTime(@start, @interval)
	
	WHILE @start < @end
	BEGIN
		DECLARE @next AS DATETIME = DATEADD(S, @interval, @start)
		
		INSERT @range VALUES(@start, @next, @interval)
		SET @start = @next
	END
	
	RETURN
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.SessionIntervalCount') and OBJECTPROPERTY(id, N'IsTableFunction') = 1)
	DROP FUNCTION dbo.SessionIntervalCount
GO

CREATE FUNCTION dbo.SessionIntervalCount(@start AS DATETIME, @end AS DATETIME = NULL, @interval AS INT = NULL)
	RETURNS @range TABLE (
	            [Database]  VARCHAR(255),
	            Environment VARCHAR(50),
				Start       DATETIME,
				[End]       DATETIME,
				Interval    INT,
				Year        AS Year(Start),
				Month       AS Month(Start),
				Day         AS Day(Start),
				Hour        AS DATEPART(HH, Start),
				Minute      AS DATEPART(MI, Start),
				Sessions    BIGINT
				PRIMARY KEY (
					[Database]  ASC,
					Environment ASC,
					Start       ASC))
AS
BEGIN
	SET @start = dbo.RoundDownTime(@start, @interval)
		
	DECLARE sids CURSOR LOCAL FAST_FORWARD 
	FOR SELECT DB.Name,
	           Environment,
	           SS.Start,
	           [End]
	    FROM CSCSession SS WITH (NOLOCK)
		LEFT  JOIN CSCDatabase       DB WITH (NOLOCK)
		ON    SS.DatabaseId = DB.Id
		LEFT JOIN CSCServer          SV WITH (NOLOCK)
		ON   SS.FirstServerId = SV.SeqNo
		AND  SS.Start >= SV.Deployed
		AND (SS.Start <  SV.Removed OR SV.Removed IS NULL)
	    WHERE SS.Start < @end
	    AND   [End] > @start 
	    AND   SS.Id IS NOT NULL 
	    AND	  SS.Id <> ''
	OPEN sids
	
	WHILE 0 = 0
	BEGIN
		DECLARE @database    AS VARCHAR(255)
		DECLARE @environment AS VARCHAR(50)
		DECLARE @sStart      AS DATETIME
		DECLARE @sEnd        AS DATETIME
		
		FETCH NEXT from sids INTO @database, @environment, @sStart, @sEnd

		IF @@fetch_status <> 0 BREAK
			
		IF NOT EXISTS (SELECT TOP 1 [Database] FROM @range WHERE [Database] = @database AND Environment = @environment)
			 INSERT @range SELECT @database, @environment, Start, [End], Interval, 0 FROM dbo.IntervalRange(@start, @end, @interval)
		
		UPDATE @range
		SET Sessions += 1
		WHERE [Database]  = @database
		AND   Environment = @environment
		AND  (@sStart <= Start AND @sEnd   >= [End] OR
			  @sStart >= Start AND @sStart <= [End] OR
			  @sEnd   >= Start AND @sEnd   <= [End])
	END
	
	CLOSE sids
	RETURN
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.SessionSummary') and OBJECTPROPERTY(id, N'IsTableFunction') = 1)
	DROP FUNCTION dbo.SessionSummary
GO

CREATE FUNCTION dbo.SessionSummary(
					@database AS VARCHAR(255),
					@start    AS DATETIME,
					@end      AS DATETIME = NULL, 
					@interval AS INT      = NULL,
					@mergeGap AS FLOAT    = 0)
	RETURNS @summary TABLE (
	            [Database]    VARCHAR(255),
	            Environment   VARCHAR(50),
	            NACSCode      VARCHAR(256),
				Timestamp     DATETIME,
				MergeGap      FLOAT,
				Interval      INT,
				Year          AS Year(Timestamp),
				Month         AS Month(Timestamp),
				Day           AS Day(Timestamp),
				Hour          AS DATEPART(HH, Timestamp),
				Minute        AS DATEPART(MI, Timestamp),
				Sessions      INT,
				Active        INT,
				MaxConcurrent INT,
				MergedURLs    INT,
				MergedElapsed DECIMAL(24, 11),
				URLs          INT,
				NoSessionURLs INT,
				Sent          BIGINT,
				Received      BIGINT,
				Duration      DECIMAL(24, 11)
				PRIMARY KEY (
					Environment ASC,
					NACSCode    ASC,
					Timestamp   ASC))
AS
BEGIN
	DECLARE @seqNo         AS BIGINT
	DECLARE @timestamp     AS DATETIME
	DECLARE @iCurrent      AS DATETIME
	DECLARE @iPrevious     AS DATETIME  = NULL
	DECLARE @sStart        AS DATETIME
	DECLARE @sEnd          AS DATETIME
	DECLARE @tStart        AS DATETIME
	DECLARE @tEnd          AS DATETIME
	DECLARE @isFixed       AS CHAR(1)
	DECLARE @environment   AS VARCHAR(50)
	DECLARE @NACSCode      AS VARCHAR(256)
	DECLARE @sessionId     AS VARCHAR(50)
	DECLARE @URLType       AS VARCHAR(255)
	DECLARE @status        AS SMALLINT
	DECLARE @sent          AS BIGINT
	DECLARE @received      AS BIGINT
	DECLARE @duration      AS BIGINT
	DECLARE @dbId          AS INT
	DECLARE @urlStart      AS DATETIME
	DECLARE @urlEnd        AS DATETIME
	DECLARE @currentURLEnd AS DATETIME
	
	DECLARE @sessions TABLE(
	            SessionId   VARCHAR(50) PRIMARY KEY,
	            Start       DATETIME,
	            [End]       DATETIME,
	            IsFixed     CHAR(1),
	            Environment VARCHAR(50),
	            NACSCode    VARCHAR(256),
	            Active      TINYINT)
	DECLARE @urls TABLE(
	            SessionId   VARCHAR(50),
	            URLStart    DATETIME,
	            URLEnd      DATETIME,
	            Environment VARCHAR(50),
	            NACSCode    VARCHAR(256)
				PRIMARY KEY (
					URLStart  ASC,
					SessionId ASC))
	            
	SET    @start = dbo.RoundDownTime(@start, @interval)
	SET    @end   = ISNULL(@end, CURRENT_TIMESTAMP)
	SELECT @dbId  = Id FROM CSCDatabase WHERE Name = @database
	
	DECLARE sids CURSOR LOCAL FAST_FORWARD 
	FOR 
	SELECT 
		WL.SeqNo,
		Timestamp,
		dbo.RoundDownTime(Timestamp, @interval) AS IntervalStart,
		ISNULL(SV.Environment, 'UNKNOWN')       AS Environment,
		ISNULL(HST.NACSCode, 'NONE')            AS NACSCode,
		SES.Id                                  AS SessionId,
		ISNULL(SES.Start, Timestamp)            AS SessionStart,
		SES.[End]                               AS SessionEnd,
		FN.URLType,
		Status,
		CAST(WL.Sent     AS BIGINT)             AS Sent,
		CAST(WL.Received AS BIGINT)             AS Received,
		WL.Duration                             AS Duration
	FROM  CSCWebLog              WL WITH (NOLOCK)
	LEFT JOIN CSCFunction        FN WITH (NOLOCK)
	ON   WL.NodeId = FN.FunctionId
	LEFT JOIN CSCServer          SV WITH (NOLOCK)
	ON   WL.ServerID   = SV.SeqNo
	AND  WL.Timestamp >= SV.Deployed
	AND (WL.Timestamp <  SV.Removed OR SV.Removed IS NULL)
	LEFT JOIN CSCHost            HST WITH (NOLOCK)
	ON   WL.HostID = HST.SeqNo
	LEFT JOIN CSCSession         SES WITH (NOLOCK)
	ON   WL.SessionID  = SES.SeqNo
	AND  WL.DatabaseId = SES.DatabaseId
	JOIN CSCDatabase             DB  WITH (NOLOCK)
	ON WL.DatabaseId = DB.Id
	WHERE Timestamp >= @start
	AND   Timestamp <  @end
	AND   WL.DatabaseId = @dbId
	ORDER BY Timestamp, WL.SeqNo, WL.DatabaseId
	OPEN sids

	WHILE 0 = 0
	BEGIN		
		FETCH NEXT from sids 
		INTO @seqNo, 
			 @timestamp,
			 @iCurrent, 
			 @environment,
			 @NACSCode,
			 @sessionId,
			 @sStart,
			 @sEnd,
			 @URLType,
			 @status,
			 @sent,
			 @received,
			 @duration

		IF (@iPrevious <> @iCurrent OR @@fetch_status <> 0) AND @iPrevious IS NOT NULL
		BEGIN
			-- We are at the start of a new time slot or have reached the end of extract range. So we
			-- need to update the cumulative session data in the session record.
			
			UPDATE SM
				SET SM.Sessions      = SS.Sessions,
					SM.Active        = SS.Active,
					SM.MergedURLs    = UR.MergedURLs,
					SM.MergedElapsed = UR.MergedElapsed
			FROM @summary SM
			LEFT JOIN (SELECT 
							Environment,
							NACSCode,
							COUNT(*)    AS Sessions,
							SUM(Active) AS Active
			           FROM @sessions
			           WHERE Start <= @iPrevious
			           AND   [End] >= @iPrevious
			           GROUP BY Environment, NACSCode) SS
			ON  SM.Environment = SS.Environment
			AND SM.NACSCode    = SS.NACSCode
			LEFT JOIN (SELECT
							Environment,
							NACSCode,
							SUM(DATEDIFF(MS, URLStart, URLEnd) / 1000.00) AS MergedElapsed,
							COUNT(*)    AS MergedURLs
			           FROM @urls
			           WHERE URLStart >= @iPrevious
			           AND   URLStart <  DATEADD(S, @interval, @iPrevious)
			           GROUP BY Environment, NACSCode) UR
			ON  SM.Environment = UR.Environment
			AND SM.NACSCode    = UR.NACSCode
			WHERE SM.Timestamp = @iPrevious
			
			-- Reduce the size of the processing tables by deleting data that is no longer required.
			
			DELETE @sessions WHERE [End]  < @iCurrent AND IsFixed = 'Y'
			DELETE @urls     WHERE URLEnd < @iCurrent
			UPDATE @sessions SET Active = 0
		END
		
		IF @@fetch_status <> 0 BREAK
		
		IF NOT EXISTS (SELECT 1 
					   FROM @summary
					   WHERE Environment = @environment
					   AND   NACSCode    = @NACSCode
					   AND   Timestamp   = @iCurrent)
			INSERT @summary VALUES (@database, @environment, @NACSCode, @iCurrent, @mergeGap, @interval, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
		SET @iPrevious     = @iCurrent
		SET @currentURLEnd = DATEADD(MS, @duration, @timestamp)

		IF @sessionId IS NULL OR LTRIM(@sessionId) = ''
		BEGIN
			-- If we don't have a session, update the summary and skip to the next URL.
			--
			-- Note: In this case we don't update the sent, received and duration fields. If this information
			--       is of interest we could add additional fields to record this for URLs not connected to
			--       a session.
			UPDATE @summary
				SET NoSessionURLs += 1
			WHERE Environment = @environment
			AND   NACSCode    = @NACSCode
			AND   Timestamp   = @iCurrent
			CONTINUE
		END
		
		UPDATE @summary
			SET URLs     += 1,
				Sent     += @sent,
				Received += @received,
				Duration += @duration / 1000.0
		WHERE Environment = @environment
		AND   NACSCode    = @NACSCode
		AND   Timestamp   = @iCurrent
		
		-- Get the session details.
		
		SET @tStart = NULL
		SELECT
			@tStart  = Start,
			@tEnd    = [End],
			@isFixed = IsFixed
		FROM @sessions
		WHERE SessionId = @sessionId
		
		-- If this is a new session create a session record for it.
		
		IF @tStart IS NULL
		BEGIN
			-- If the session end is not known, set it to the URL end time and set IsFixed to N.
			--
			-- Note: The Start and End fields may not be populated. These fields were introduced to avoid the cost
			--       of deriving them from the weblogs. If they are not present, we set the Start to the that of
			--       the first URL referencing it and we continually update the End for each URL. 
			--
			--       There is an inaccuracy in this in that the start of the session will be missed if it occurs before
			--       the start of the summary range. This can be rectified by finding the oldest URL referencing the
			--       session. However, this would be costly and the inaccuracy will be small if the extract range starts
			--       when few sessions are active and in any event will be less further into the extract range.
			INSERT @sessions 
			VALUES (
				@sessionId, 
				@iCurrent,
				ISNULL(@sEnd, @currentURLEnd),
				CASE @sEnd WHEN NULL THEN 'N' ELSE 'Y' END,
				@environment, 
				@NACSCode, 
				1)
		END
		ELSE IF @currentURLEnd > @sEnd
		BEGIN
			-- The session end point has changed so update it and changed it to not fixed end point.
			
			UPDATE @sessions
				SET [End]   = @currentURLEnd,
					IsFixed = 'N',
					Active  = 1
			WHERE SessionId = @sessionId
			
			-- Need to add 1 to all summary records between the previous session end and the new summary record.
			
			UPDATE @summary
				SET Sessions += 1
			WHERE Environment = @environment
			AND   NACSCode    = @NACSCode
			AND   Timestamp > @tEnd
			AND	  Timestamp < @iCurrent
		END
		ELSE
			UPDATE @sessions SET Active = 1 WHERE SessionId = @sessionId
		
		-- Find if there is a URL for the session that overlaps the start of the current.

		SET @urlStart = NULL
		SET @urlEnd   = NULL
		SELECT 
			@urlStart = URLStart, 
			@urlEnd   = URLEnd
		FROM @urls
		WHERE URLStart <= @timestamp
		AND   URLEnd   >= @timestamp
		AND   SessionId = @sessionId

		-- Add mergeGap to the actual duration so that we overlap the start of the next URL if it starts in
		-- less than merge gap seconds after the end of the current.
		
		SET @currentURLEnd = DATEADD(MS, 1000 * @mergeGap, @currentURLEnd)
		
		-- If there is one and it contains the new one then no further action is required
		
		IF @urlStart IS NULL
			-- Create a new entry in @urls
			
			INSERT @urls VALUES(@sessionId, @timestamp, @currentURLEnd, @environment, @NACSCode)
		ELSE IF @currentURLEnd > @urlEnd
			-- Update the end point of the existing URL. Could also delete it and
			-- create a new @url entry for the current
			
			UPDATE @urls
				SET URLEnd = @currentURLEnd 
			WHERE SessionId = @sessionId
			AND   URLStart = @urlStart
			
		UPDATE @summary
			SET MaxConcurrent = C.Count
		FROM @summary S
		JOIN (SELECT COUNT(*) AS Count
			  FROM @urls
			  WHERE URLStart   <= @timestamp
			  AND   URLEnd     >= @timestamp
			  AND   Environment = @environment
			  AND   NACSCode    = @NACSCode) C
		ON  S.MaxConcurrent  < C.Count
		AND S.Timestamp      = @iCurrent
		AND S.Environment    = @environment
		AND S.NACSCode       = @NACSCode
	END
	
	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'MergeSecurityLogRange' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE MergeSecurityLogRange
GO
CREATE PROCEDURE MergeSecurityLogRange(
					@logDBId   INT, 
					@AMSDBId   INT,
					@StartOID  BIGINT OUTPUT,
					@maxRows   INT,
					@log       CHAR,
					@loaded    INT OUTPUT,
					@sessionNo INT OUTPUT,
					@missing   INT OUTPUT)
AS
	SET NOCOUNT on
BEGIN
	DECLARE @sql     AS VARCHAR(max)
	DECLARE @started AS DATETIME
	DECLARE @timer   AS DATETIME 
	
	SET @started = CURRENT_TIMESTAMP
	SET @timer   = CURRENT_TIMESTAMP
	
	IF @maxRows IS NULL OR @maxRows = 0
		SET @sql = 'SELECT'
	ELSE	
		SET @sql = 'SELECT TOP ' + CAST(@maxRows AS VARCHAR)
		
	SET @sql = @sql + 
		   ' AMS.OID                              AS SecOID,
		     AMS.CreatedAt                        AS AMSCreated,
		     AMS.ModifiedAt                       AS AMSModified,
		     dbo.GetPrefix(AMS.SessionKey, ''#'') AS SessionKey,
			 S.SeqNo                              AS SessionNo,
			 L.SeqNo                              AS LoginNo,
			 AMS.LoginName                        AS Name,
			 AMS.UsersOID,
			 ISNULL(AMS.OrganisationOID, -1)      AS OrganisationOID
		FROM ' + dbo.QualifyTable(@AMSDBId, 'SecuritySession') + ' AMS WITH (NOLOCK) 
	    LEFT JOIN CSCSession S WITH (NOLOCK)
	    ON        dbo.GetPrefix(AMS.SessionKey, ''#'') = S.Id
	    AND       S.DatabaseId = ' + STR(@logDBId) + '
	    LEFT JOIN CSCMissingSession M WITH (NOLOCK)
	    ON        M.DatabaseId = ' + STR(@AMSDBId) + '
	    AND       AMS.OID = M.SecOID
	    LEFT JOIN CSCLogin L  WITH (NOLOCK) 
	    ON        AMS.LoginName                   = L.Name
	    AND       ISNULL(AMS.OrganisationOID, -1) = L.OrganisationOID
	    AND       AMS.UsersOID                    = L.UsersOID
	    WHERE S.SecOID IS NULL
	    AND   M.SecOID IS NULL
	    AND   AMS.OID > ' + LTRIM(STR(@StartOID)) + ' 
	    ORDER BY AMS.OID'
	    
	DECLARE @sec TABLE (SecOID          BIGINT PRIMARY KEY,
						AMSCreated      DATETIME, 
						AMSModified     DATETIME, 
	                    SessionKey      VARCHAR(50), 
	                    SessionNo       INT, 
	                    LoginNo         INT,
	                    Name            VARCHAR(256),
	                    UserOID         BIGINT,
	                    OrganisationOID BIGINT)
	INSERT INTO @sec EXEC (@sql)
		
	IF @log = 'D' EXEC ReportTimeTaken 'Sec load', @timer OUTPUT
	
	INSERT INTO CSCLogin(Name, UsersOID, OrganisationOID)
	SELECT DISTINCT S.Name, S.UserOID, OrganisationOID
	FROM  @sec S
	WHERE LoginNo IS NULL
		
	UPDATE @sec
		SET LoginNo = L.SeqNo
	FROM @sec S
	JOIN CSCLogin L
	ON   S.Name = L.Name
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update login', @timer OUTPUT
	
	UPDATE S
		SET S.LoginId = SC.LoginNo,
			S.SecOID  = SC.SecOID
	FROM @sec SC
	LEFT JOIN CSCSession  S
	ON SC.SessionNo = S.SeqNo
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update session', @timer OUTPUT
	
	INSERT INTO CSCMissingSession(DatabaseId, SecOID, LoginId, AMSCreated, AMSModified, SessionKey)
	SELECT @AMSDBId, SC.SecOID, SC.LoginNo, SC.AMSCreated, SC.AMSModified,  SC.SessionKey
	FROM @sec SC
	WHERE SC.SessionNo IS NULL
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update missing', @timer OUTPUT
	
	SELECT @StartOID  = ISNULL(MAX(SecOID), @StartOID) FROM @sec
	SELECT @missing  += ISNULL(COUNT(*), 0)            FROM @sec WHERE SessionNo IS NULL
	SELECT 
		@loaded    = ISNULL(COUNT(*), 0), 
		@sessionNo = ISNULL(MIN(SessionNo),0) 
	FROM @sec
	WHERE SessionNo IS NOT NULL
	
	IF @log = 'D' EXEC ReportTimeTaken 'Update counts', @timer OUTPUT
	
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'MergeSecurityLog' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE MergeSecurityLog
GO

CREATE PROCEDURE MergeSecurityLog(
					@logDatabase VARCHAR(20),
					@AMSDatabase VARCHAR(20),
					@batchSize   INT  = 1000, 
					@maxRows     INT  = NULL,
					@log         CHAR = 'Y')
AS
	SET NOCOUNT on
BEGIN
	DECLARE @logDB    AS INT
	DECLARE @AMSDB    AS INT
	DECLARE @timer    AS DATETIME = CURRENT_TIMESTAMP
	DECLARE @loaded   AS INT      = 0
	DECLARE @start    AS INT      = 0
	DECLARE @missing  AS INT      = 0
	DECLARE @total    AS INT      = 0
	DECLARE @startOID AS BIGINT   = 0
	
	EXEC GetdatabaseId @logDatabase, @logDB OUTPUT
	
	IF @logDB IS NULL RETURN
	
	EXEC GetdatabaseId @AMSDatabase, @AMSDB OUTPUT
	
	IF @AMSDB IS NULL RETURN
	
	SELECT @startOID = ISNULL(Max(SecOID), 0) 
	FROM CSCSession 
	WHERE SecOID IS NOT NULL
	
	WHILE 0 = 0
	BEGIN
		BEGIN TRY
			EXEC MergeSecurityLogRange 
					@logDB, 
					@AMSDB, 
					@startOID OUTPUT, 
					@batchSize, 
					@log, 
					@loaded	  OUTPUT, 
					@start    OUTPUT, 
					@missing  OUTPUT
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
					'In batch starting %i error %i in %s(%i) %s',
					@errorSeverity,
					@errorState, 
					@start,
					@errorNumber,
					@errorProcedure,
					@errorLine,
					@errorMessage)
				RETURN
		END CATCH
		
		SET @maxRows -= @loaded
		SET @total   += @loaded
		
		IF @log <> 'N' AND @loaded <> 0
		BEGIN
			DECLARE @message AS VARCHAR(MAX)
			
			SET @message = 
					'Starting at Session Seq ' + STR(@start, 8) +
					' AMS OID '  + STR(@startOID, 8) +
					' merge of ' + STR(@loaded,   6) + ' AMS sessions'
			EXEC ReportTimeTaken @message, @timer OUTPUT
		END
		
		IF @maxRows <= 0 OR @loaded = 0 BREAK
	END

	IF @missing = 0
		PRINT 'Merged ' + LTRIM(STR(@total)) + ' AMS sessions '
	ELSE
		PRINT 'Merged ' + LTRIM(STR(@total)) + ' AMS sessions ' + LTRIM(STR(@missing)) + ' not found in CSCSession'
	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'LoadTestURLs' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE LoadTestURLs
GO

CREATE PROCEDURE LoadTestURLs(
						@database   AS VARCHAR(50) = 'DevTest',
						@delete     AS CHAR(1)     = 'Y',
						@sendMax    AS INT         = 1000,
						@receiveMax AS INT         = 1000)
AS
	SET NOCOUNT on
BEGIN
	DECLARE @dbID       AS SMALLINT
	DECLARE @urlStart   AS DATETIME
	DECLARE @urlEnd     AS DATETIME
	DECLARE @duration   AS DECIMAL(24,11)
	DECLARE @sessionId  AS VARCHAR(50)
	DECLARE @sessionSeq AS INT
	DECLARE @hostId     AS INT
	DECLARE @serverId   AS INT
	DECLARE @functionId AS INT
	DECLARE @urlSeqNo   AS BIGINT
		
	SELECT @dbID = Id FROM CSCDatabase WHERE Name = @database

	IF @delete = 'Y' 
	BEGIN
		DELETE CSCWeblog  WHERE DatabaseId = @dbId
		DELETE CSCSession WHERE DatabaseId = @dbId
	END
	
	SELECT @urlSeqNo = ISNULL(MAX(SeqNo), 0) FROM CSCWeblog WHERE DatabaseId = @dbId
	
	DECLARE urls CURSOR LOCAL FAST_FORWARD 
	FOR 
	SELECT 
		Timestamp                               AS URLStart,
		DATEADD(MS, 1000 * Duration, Timestamp) AS URLEnd,
		Duration,
		Session                                 AS SessionId,
		COALESCE(H1.HostID, H2.HostID)          AS HostID,
		COALESCE(SV1.ServerID, SV2.ServerID)    AS ServerID,
		F.FunctionId
	FROM  TestURLS U
	LEFT JOIN (SELECT NACSCode, Min(SeqNo) AS HostId
	           FROM CSCHost
	           GROUP BY NACSCode) H1
	ON U.NACSCode = H1.NACSCode
	LEFT JOIN (SELECT URLType, Min(FunctionID) AS FunctionId
			   FROM CSCFunction
			   GROUP BY URLType) F
	ON U.URLType = F.URLType
	LEFT JOIN (SELECT Environment, Min(SeqNo) AS ServerId
			   FROM CSCServer
			   GROUP BY Environment) SV1
	ON U.Environment = SV1.Environment,
	(SELECT TOP 1 SeqNo AS HostId
	           FROM CSCHost
	           WHERE NACSCode IS NULL) H2,
	(SELECT TOP 1 SeqNo AS ServerId FROM CSCServer) SV2
	
	OPEN urls
	
	WHILE 0 = 0
	BEGIN		
		FETCH NEXT
		FROM urls
		INTO @urlStart,
			 @urlEnd,
			 @duration,
			 @sessionId,
			 @hostId,
			 @serverId,
			 @functionId
		
		IF @@fetch_status <> 0 BREAK
		
		SET @sessionSeq = NULL
		SELECT @sessionSeq = SeqNo 
		FROM CSCSession
		WHERE DatabaseId = @dbID
		AND   Id         = @sessionId
		
		IF @sessionSeq IS NULL
		BEGIN
			INSERT CSCSession(DatabaseId, Id, Start, [End])
			VALUES(@dbID, @sessionId, @urlStart, @urlEnd)
			SELECT @sessionSeq = SCOPE_IDENTITY()
		END
		ELSE
			UPDATE CSCSession
				SET Start = CASE  WHEN Start > @urlStart THEN @urlStart ELSE Start END,
					[End] = CASE  WHEN [End] < @urlEnd   THEN @urlEnd   ELSE [End] END
			WHERE SeqNo = @sessionSeq
	
		SET @urlSeqNo = @urlSeqNo + 1
		INSERT INTO  CSCWebLog
           (DatabaseId
           ,SeqNo
           ,Timestamp
           ,ServerID
           ,HostID
           ,NodeId
           ,SessionID
           ,Status
           ,Sent
           ,Received
           ,Duration)
		VALUES
           (@dbID
           ,@urlSeqNo
           ,@urlStart
           ,@serverId
           ,@hostId
           ,@functionId
           ,@sessionSeq
           ,200
           ,@sendMax
           ,@receiveMax
           ,1000 * @duration)
	END
	RETURN
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UpdateSession' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE UpdateSession
GO

CREATE PROCEDURE UpdateSession(@count AS INT OUTPUT)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @seqNo   AS INT
	DECLARE @timer   AS DATETIME  = CURRENT_TIMESTAMP
	DECLARE @message AS VARCHAR(max)
	
	DECLARE @updated TABLE (SeqNo INT)
	
	UPDATE S2
		SET Start         = S1.Start,
			[End]         = S1.[End],
			FirstHostId   = S1.FirstHostId,
			FirstServerId = S1.FirstServerId,
			URLs          = S1.URLs,
			Sent          = S1.Sent,
			Received      = S1.Received,
			URLDuration   = S1.URLDuration
		OUTPUT DELETED.SeqNo
		INTO @updated
	FROM (SELECT 
			S.DatabaseId,
			S.SeqNo, 
			min(Timestamp)                        AS Start, 
			MAX(DATEADD(MS, Duration, Timestamp)) AS [End],
			MIN(ServerId)                         AS FirstServerId,
			MIN(HostId)                           AS FirstHostId,
			COUNT(*)                              AS URLs,
			SUM(Sent)                             AS Sent,
			SUM(Received)                         AS Received,
			SUM(Duration)                         AS URLDuration 
		  FROM (SELECT TOP 10000
					DatabaseId, 
					SeqNo
				FROM  CSCSession 
				WHERE Start IS NULL
				ORDER BY SeqNo DESC) S
	LEFT JOIN CSCWebLog W
	ON  S.SeqNo      = W.SessionID
	AND S.DatabaseId = W.DatabaseId
	GROUP BY S.DatabaseId, S.SeqNo) S1
	JOIN CSCSession S2
	ON  S1.DatabaseId = S2.DatabaseId
	AND S1.SeqNo      = S2.SeqNo

	SELECT @seqNo = MIN(SeqNo), @count = ISNULL(Count(*), 0) FROM @updated
	
	IF @count <> 0
	BEGIN
		SET @message = 'Starting at ' + LTRIM(STR(@seqNo)) + ' update of 10000 sessions'
		EXEC ReportTimeTaken @message, @timer OUTPUT
	END
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'UpdateSessions' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE UpdateSessions
GO

CREATE PROCEDURE UpdateSessions(@iterations AS INT)
AS
BEGIN
	SET NOCOUNT ON
	
	DECLARE @count AS INT = 1000
	
	WHILE @iterations > 0 AND @count <> 0
	BEGIN
		EXEC UpdateSession @count OUTPUT
		SET @iterations -= 1
	END
END	
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'PopulateReferrerId' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE PopulateReferrerId
GO

CREATE PROCEDURE PopulateReferrerId(@start AS DATETIME, @end AS DATETIME, @batchMinutes AS INT)
AS
BEGIN
	SET NOCOUNT on
	
	DECLARE @timer    AS DATETIME = CURRENT_TIMESTAMP
	DECLARE @batchEnd AS DATETIME
	DECLARE @message  AS VARCHAR(max)
	
	WHILE @start < @end
	BEGIN
		SET @batchEnd = DATEADD(mi, @batchMinutes, @start)
		
		IF @batchEnd > @end SET @batchEnd = @end
		
		BEGIN TRY
			UPDATE CL
				SET CL.ReferrerId = FN.FunctionId
				FROM CSCWebLog          CL
				JOIN IISLogs.dbo.WebLog WL
				ON  CL.SeqNo = WL.SeqNo
				AND WL.Referrer IS NOT NULL
				AND WL.Referrer <> '-'
				LEFT JOIN CSCFunction FN
				ON   dbo.GetURIStem(WL.Referrer, 255) = FN.Name
				AND  FN.Type     = 'ASP Page'
				WHERE ReferrerId IS NULL
				AND   CL.Timestamp >= @start
				AND   CL.Timestamp <  @batchEnd		
			SET @message = 'Batch starting at ' + CAST(@start AS VARCHAR(30)) + ' update of ' + LTRIM(STR(@@ROWCOUNT)) + ' records'
			EXEC ReportTimeTaken @message, @timer OUTPUT		
			SET @start = @batchEnd
		END TRY

		BEGIN CATCH
			DECLARE @errorNumber    AS INT
			DECLARE @errorSeverity  AS INT
			DECLARE @errorState     AS INT
			DECLARE @errorProcedure AS NVARCHAR(max)
			DECLARE @errorLine      AS INT
			DECLARE @errorMessage   AS NVARCHAR(max)
			DECLARE @tStart         AS VARCHAR(30) = CAST(@start AS VARCHAR(30))
			
			SELECT
				@errorNumber    = ERROR_NUMBER(),
				@errorSeverity  = ERROR_SEVERITY(),
				@errorState     = ERROR_STATE(),
				@errorProcedure = ERROR_PROCEDURE(),
				@errorLine      = ERROR_LINE(),
				@errorMessage   = ERROR_MESSAGE()
				
				RAISERROR(
					'In batch starting %i error %i in %s(%i) %s',
					@errorSeverity,
					@errorState, 
					@tStart,
					@errorNumber,
					@errorProcedure,
					@errorLine,
					@errorMessage)
				RETURN
		END CATCH
	END
END
GO