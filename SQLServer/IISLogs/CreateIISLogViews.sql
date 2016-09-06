IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWWebLog' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWWebLog
GO

CREATE VIEW CSCVWWebLog
AS
SELECT DB.Name                     AS [Database],
       WL.SeqNo,
       Timestamp,
       Year,
       Month,
       Day,
       Hour,
       Week,
       Weekday,
       EN.Environment,
       FN.Usage,
       HST.Identifier              AS Host,
       HST.Name                    AS HostName,
       HST.NACSCode                AS NACSCode,
       SV.ManIP                    AS Server,
       UA.Name                     AS UserAgent,
       SV.Tower,
       SES.Id                      AS SessionId,
       LG.Name                     AS Login,
       FN.Name                     AS URLFile,
       FN.URLPath,
       FN.URLName,
       FN.URLType,
       RF.Name                     AS ReferrerFile,
       RF.URLPath                  AS ReferrerPath,
       RF.URLName                  AS ReferrerName,
       RF.URLType                  AS ReferrerType,
       SIP.IP,
       Method,
       Status,
       CAST(WL.Sent     AS BIGINT) AS Sent,
       CAST(WL.Received AS BIGINT) AS Received,
       WL.Duration / 1000.0        AS Duration,
       WL.Gap / 1000.0             AS Gap,
       WL.MergeDuration / 1000.0   AS MergeDuration
FROM  CSCWebLog              WL WITH (NOLOCK)
LEFT  JOIN CSCDatabase       DB WITH (NOLOCK)
ON    WL.databaseId = DB.Id
LEFT JOIN CSCFunction        FN WITH (NOLOCK)
ON   WL.NodeId = FN.FunctionId
LEFT JOIN CSCFunction        RF WITH (NOLOCK)
ON   WL.ReferrerId = RF.FunctionId
LEFT JOIN CSCServer          SV WITH (NOLOCK)
ON   WL.ServerID = SV.SeqNo
AND  WL.Timestamp >= SV.Deployed
AND (WL.Timestamp <  SV.Removed OR SV.Removed IS NULL)
LEFT JOIN CSCEnvironment     EN  WITH (NOLOCK)
ON   SV.Environment = EN.Environment
LEFT JOIN CSCHost           HST WITH (NOLOCK)
ON   WL.HostID = HST.SeqNo
LEFT JOIN CSCUserAgent      UA WITH (NOLOCK)
ON   WL.UserAgentID = UA.SeqNO
LEFT JOIN CSCSourceIPs      SIP WITH (NOLOCK)
ON   WL.IPID = SIP.SeqNo
LEFT JOIN CSCSession        SES WITH (NOLOCK)
ON   WL.SessionID = SES.SeqNo
AND  WL.DatabaseId = SES.DatabaseId
LEFT JOIN CSCLogin LG
ON SES.LoginId = LG.SeqNo
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWFullWebLog' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWFullWebLog
GO

CREATE VIEW CSCVWFullWebLog
AS
SELECT CWL.*,
       WL.URIQuery
FROM CSCVWWebLog CWL
LEFT JOIN IISLogs.dbo.WebLog WL
ON CWL.SeqNo = WL.SeqNo
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWSessionOld' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWSessionOld
GO

CREATE VIEW CSCVWSessionOld
AS
SELECT DB.Name                         AS [Database],
       Environment,
       S2.Id                           AS SessionId,
       S1.Start,
       DATEPART(yy, S1.Start)          AS Year,
       DATEPART(mm, S1.Start)          AS Month,
       DATEPART(dd, S1.Start)          AS Day,
       DATEPART(hh, S1.Start)          AS Hour,
       DATEPART(wk, S1.Start)          AS Week,
       DATEPART(dw, S1.Start)          AS Weekday,
       S1.[End],
       DATEDIFF(s, S1.Start, S1.[End]) AS Duration,
       HST.Name                        AS Host,
       S1.URLs,
       S1.Sent,
       S1.Received,
       S1.Duration                     AS URLDuration
FROM (SELECT DatabaseId,
             Environment,
             SessionID,
             MIN(Timestamp) AS Start,
             MAX(Timestamp) AS [End],
             MIN(HostID)    AS Host,
             COUNT(NodeId)  AS URLs,
             SUM(Sent)      AS Sent,
             SUM(Received)  AS Received,
             SUM(Duration)  AS Duration
      FROM CSCWebLog       WL WITH (NOLOCK)
	  LEFT JOIN CSCServer  SV WITH (NOLOCK)
	  ON   WL.ServerID = SV.SeqNo
	  AND  WL.Timestamp >= SV.Deployed
	  AND (WL.Timestamp <  SV.Removed OR SV.Removed IS NULL)
      WHERE SessionID IS NOT NULL
      GROUP BY DatabaseId, SV.Environment, SessionID) S1
LEFT JOIN CSCSession S2   WITH (NOLOCK)
ON  S1.DatabaseId = S2.DatabaseId
AND S1.SessionID = S2.SeqNo
LEFT JOIN CSCDatabase DB  WITH (NOLOCK)
ON  S1.DatabaseId = DB.Id
LEFT JOIN CSCHost HST     WITH (NOLOCK)
ON   S1.Host = HST.SeqNo
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWSession' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWSession
GO

CREATE VIEW CSCVWSession
AS
SELECT D.Name                    AS [Database],
       SV.Environment,
       SS.SeqNo                  AS SessionSeqNo,
       SS.SecOID                 AS AMSOID,
       SS.Id                     AS SessionId,
       LG.Name                   AS Login,
       Start,
       DATEPART(yy, Start)       AS Year,
       DATEPART(mm, Start)       AS Month,
       DATEPART(dd, Start)       AS Day,
       DATEPART(hh, Start)       AS Hour,
       DATEPART(wk, Start)       AS Week,
       DATEPART(dw, Start)       AS Weekday,
       [End],
       DATEDIFF(s, Start, [End]) AS Duration,
       HST.NACSCode,
       HST.Name                  AS Host
FROM CSCSession SS   WITH (NOLOCK)
LEFT JOIN CSCDatabase D
ON  SS.DatabaseId = D.Id
LEFT JOIN CSCHost HST     WITH (NOLOCK)
ON   SS.FirstHostId = HST.SeqNo
LEFT JOIN CSCServer SV WITH (NOLOCK)
ON   SS.FirstServerId = SV.SeqNo
LEFT JOIN CSCLogin LG WITH (NOLOCK)
ON   SS.LoginId = LG.SeqNo
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWSessionSummary' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWSessionSummary
GO

CREATE VIEW CSCVWSessionSummary
AS
SELECT Host,
       Min(Start) AS First,
       Year,
       Month,
       Day,
       Hour,
       Min(Weekday)                 AS WeekDay,
       Count(*)                     AS Sessions,
       Avg(URLs)                    AS AvgURLs,
       Sum(URLs)                    AS TotURLs,
       Avg(Duration)                AS AvgDuration,
       Sum(Duration)                AS TotDuration,
       Sum(Sent)                    AS TotSent,
       Sum(Received)                AS TotReceived,
       Sum(URLDuration)             AS TotURLDuration,
       Sum(Sent)        / Sum(Urls) AS AvgURLSent,
       Sum(Received)    / Sum(Urls) AS AvgURLReceived,
       Sum(URLDuration) / Sum(Urls) AS AvgURLDuration
FROM CSCVWSessionOld
GROUP BY Host, Year, Month, Day, Hour
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWServerSummary' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWServerSummary
GO

CREATE VIEW CSCVWServerSummary
AS
SELECT Min(Tower)                    AS Tower,
       Year,
       Month, 
       Day,
       URLType,
       COUNT(*)                      AS Count,
       AVG(Duration)                 AS AvgDuration,
       AVG(CAST(Sent AS BIGINT))     AS AvgSent,
       AVG(CAST(Received AS BIGINT)) AS AvgReceived
FROM CSCVWWebLog
GROUP BY Server, Year, Month, Day, URLType
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWDailySummary' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWDailySummary
GO

CREATE VIEW CSCVWDailySummary
AS
SELECT Environment,
       MIN(Timestamp)                AS Timestamp,
       Year,
       Month, 
       Day,
       Usage,
       URLType,
       COUNT(*)                      AS Count,
       MIN(Duration)                 AS MinDuration,
       AVG(Duration)                 AS AvgDuration,
       MAX(Duration)                 AS MaxDuration,
       MIN(CAST(Sent AS BIGINT))     AS MinSent,
       AVG(CAST(Sent AS BIGINT))     AS AvgSent,
       MAX(CAST(Sent AS BIGINT))     AS MaxSent,
       MIN(CAST(Received AS BIGINT)) AS MinReceived,
       AVG(CAST(Received AS BIGINT)) AS AvgReceived,
       MAX(CAST(Received AS BIGINT)) AS MaxReceived
FROM CSCVWWebLog
GROUP BY Environment, Year, Month, Day, Usage, URLType
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWSession5Minutes' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWSession5Minutes
GO

CREATE VIEW CSCVWSession5Minutes
AS
SELECT [Database], 
       Environment,
       CAST(STR(Year) + '/' + STR(Month) + '/' + STR(Day) + ' ' + STR(Hour) + ':' + STR(5 * (DATEPART(mi, timestamp) / 5)) AS DATETIME) AS Timestamp,
       Year, 
       Month, 
       Day, 
       Hour,
       5 * (DATEPART(mi, timestamp) / 5) AS Minutes,
       SessionId,
	   COUNT(*) AS URLS,
       Sum(Sent)  AS Sent,
       SUM(Received)  AS       Received,
       SUM(Duration) AS Duration
FROM CSCVWWebLog
WHERE SessionId IS NOT NULL
AND	  SessionId <> ''
AND   URLType IN ('aspx', 'axd', 'htm')
GROUP BY [Database], Environment, Year, Month, Day, Hour, 5 * (DATEPART(mi, timestamp) / 5), Sessionid

GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWServerDetails' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWServerDetails
GO
CREATE VIEW CSCVWServerDetails
AS
SELECT 
	DB.Name                                                       AS [Database],
	SU.Date,
	SU.Created,
	SU.Updated,
	SU.Updates,
	DATEDIFF(S, SU.Created, SU.Updated)                           AS Duration,
	DATEDIFF(S, SU.Created, SU.Updated) / SU.Updates              AS AvgUpdateDuration,
	ROUND(DATEDIFF(S, SU.Created, SU.Updated) / 1.0 / SU.URLs, 5) AS AvgURLDuration,
	SV.Environment,
	SV.Name                                                       AS Server,
	SV.ManIP,
	SV.Tower,
	SU.URLs,
	SU.SessionURLs,
	ROW_NUMBER() OVER (PARTITION BY SV.Name ORDER BY Date DESC)    AS ServerRow
FROM CSCServerUpdate SU
LEFT JOIN CSCServer SV
ON  SU.ServerId = SV.SeqNo
LEFT JOIN CSCDatabase DB
ON  SU.DatabaseId = DB.Id
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWLoadSummary' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWLoadSummary
GO

CREATE VIEW CSCVWLoadSummary
AS
SELECT 
	[Database],
	Date,
	DATEPART(W, Date) AS Weekday,
	Min(Created)      AS Created,
	Max(Updated)      AS Updated,
	Sum(Updates)      AS Updates,
	Environment,
	'N'               AS Sessions,
	Count(*)          AS Servers,
	SUM(URLs)         AS URLs,
	0                 AS SessionURLs
FROM CSCVWServerDetails
WHERE SessionURLs = 0
GROUP BY [Database], Date, Environment
UNION
SELECT 
	[Database],
	Date, 
	DATEPART(W, Date) AS Weekday,
	Min(Created)      AS Created,
	Max(Updated)      AS Updated,
	Sum(Updates)      AS Updates,
	Environment,
	'Y'               AS Sessions,
	Count(*)          AS Servers,
	SUM(URLs)         AS URLs,
	SUM(SessionURLs)  AS SessionURLs
FROM CSCVWServerDetails
WHERE SessionURLs <> 0
GROUP BY [Database], Date, Environment
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWFullWebLog' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWFullWebLog
GO

CREATE VIEW CSCVWFullWebLog
AS
SELECT CWL.*,
       WL.URIQuery
FROM CSCVWWebLog CWL
LEFT JOIN IISLogs.dbo.WebLog WL
ON CWL.SeqNo = WL.SeqNo
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCVWURLHourlySummary' AND TABLE_TYPE=N'VIEW')
 DROP VIEW CSCVWURLHourlySummary
GO

CREATE VIEW CSCVWURLHourlySummary
AS
SELECT DB.Name                      AS [Database],
       Timestamp,
       Year,
       Month,
       Day,
       Hour,
       Weekday,
       EN.Environment,
       UR.Name                      AS URLFile,
       UR.URLPath,
       UR.URLName,
       UR.URLType,
       RF.Name                      AS ReferrerFile,
       RF.URLPath                   AS ReferrerPath,
       RF.URLName                   AS ReferrerName,
       RF.URLType                   AS ReferrerType,
       Method,
       Status,
       Count,
       AvgSent,
       AvgReceived,
       Round(AvgDuration / 1000, 3) AS AvgDuration
FROM  CSCURLHourlySummary    HS WITH (NOLOCK)
LEFT  JOIN CSCDatabase       DB WITH (NOLOCK)
ON    HS.databaseId = DB.Id
LEFT JOIN CSCFunction        UR WITH (NOLOCK)
ON   HS.URLId = UR.FunctionId
LEFT JOIN CSCFunction        RF WITH (NOLOCK)
ON   HS.ReferrerId = RF.FunctionId
LEFT JOIN CSCEnvironment     EN  WITH (NOLOCK)
ON   HS.EnvironmentId = EN.EnvironmentId
GO
