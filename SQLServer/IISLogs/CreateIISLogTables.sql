
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCSessionLoad') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE CSCSessionLoad 
GO

CREATE TABLE CSCSessionLoad(
	First    INT      NULL,
	Last     INT      NULL,
	Updated  DATETIME NULL,
	History  CHAR     DEFAULT 'N',
	Start    DATETIME NULL,
	Sessions INT      NULL,
	URLs     INT      NULL,
	Gaps     INT      NULL,
	Duration FLOAT    NULL
) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCSessionLoadHistory') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE CSCSessionLoadHistory 
GO

CREATE TABLE CSCSessionLoadHistory(
	SeqNo     INT IDENTITY(1,1) NOT NULL Primary Key,
	Timestamp DATETIME NULL,
	First     INT      NULL,
	Start     DATETIME NULL,
	Sessions  INT      NULL,
	URLs      INT      NULL,
	Gaps      INT      NULL,
	Duration  FLOAT    NULL
) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCSourceIPs') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE CSCSourceIPs 
GO

CREATE TABLE CSCSourceIPs(
	SeqNo      SMALLINT IDENTITY(1,1) NOT NULL Primary Key,
	IP         VARCHAR(50)            NULL,
	Location   VARCHAR(128)           NULL,
    Discovered DATETIME)
ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCUserAgent') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE CSCUserAgent 
GO

CREATE TABLE CSCUserAgent(
	SeqNo      SMALLINT IDENTITY(1,1) NOT NULL Primary Key,
	Name       VARCHAR(1000)          NULL,
    Discovered DATETIME)
ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX IDXUserAgentName ON CSCUserAgent
(
	Name ASC
)
INCLUDE (SeqNo) 
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO



IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCHost') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE CSCHost 
GO

CREATE TABLE CSCHost(
	SeqNo      SMALLINT IDENTITY(1,1) NOT NULL Primary Key,
	Name	   VARCHAR(128)           NULL,
	Identifier VARCHAR(128)           NOT NULL,
    NACSCode   VARCHAR(256)           NULL,
    Type       VARCHAR(128)           NULL,
    Discovered DATETIME)
ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCServer') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE CSCServer 
GO

CREATE TABLE CSCServer(
	SeqNo       SMALLINT IDENTITY(1,1) NOT NULL Primary Key,
	Name        VARCHAR(128)           NULL,
	ManIP       VARCHAR(50)            NULL,
	ProdIP      VARCHAR(50)            NULL,
	Tower       VARCHAR(10)            NULL,
	Deployed    DATETIME               NULL,
	Type        VARCHAR(30)            NULL,
	Environment VARCHAR(50)            NULL,
	Ignore      CHAR(1)                NULL,
	Removed     DATETIME               NULL)
ON [PRIMARY]
GO

ALTER TABLE CSCServer ADD  CONSTRAINT DF_CSCServer_Type    DEFAULT 'Presentation' FOR Type
GO
ALTER TABLE CSCServer ADD  CONSTRAINT DF_CSCServer_Ignore  DEFAULT 'N'            FOR Ignore
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'CSCServerUpdate') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE CSCServerUpdate 
GO

CREATE TABLE CSCServerUpdate(
	DatabaseId  SMALLINT NOT NULL,
	ServerId    INT      NOT NULL,
	Date        DATE     NOT NULL,
	Created     DATETIME DEFAULT CURRENT_TIMESTAMP,
	Updated     DATETIME,
	Updates     INT      DEFAULT 0,
	URLs        BIGINT,
	SessionURLs BIGINT
 CONSTRAINT PK_CSCServerUpdate PRIMARY KEY CLUSTERED 
(
	ServerId   ASC,
	DatabaseId ASC,
    Date       ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
)
ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCWebLog'AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE CSCWebLog
GO

CREATE TABLE CSCWebLog(
	DatabaseId    SMALLINT       NOT NULL,
	SeqNo         BIGINT         NOT NULL,
	Timestamp     datetime       NOT NULL,
    Year          AS DATEPART(yy, Timestamp),
    Month         AS DATEPART(mm, Timestamp),
    Day           AS DATEPART(dd, Timestamp),
    Hour          AS DATEPART(hh, Timestamp),
    Week          AS DATEPART(wk, Timestamp),
    WeekDay       AS DATEPART(dw, Timestamp),
    ServerID      SMALLINT       NOT NULL,
	HostID        SMALLINT       NOT NULL,
	NodeId        INT            NOT NULL,
	ReferrerId    SMALLINT       NULL,
	IPID          SMALLINT       NULL,
	UserAgentId   SMALLINT       NULL,
	SessionID     INT            NULL,
	Method        CHAR           NULL,
	Status        SMALLINT       NULL,
	Sent          INT            NULL,
	Received      INT            NULL,
	Duration      INT            NOT NULL,
	Gap           INT            NULL,
	MergeDuration INT            NULL,
 CONSTRAINT PK_CSCWebLog PRIMARY KEY CLUSTERED 
(
    Timestamp  ASC,
	SeqNo      ASC,
	DatabaseId ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE CSCWebLog  WITH CHECK ADD  CONSTRAINT FK1_CSCWebLog FOREIGN KEY(DatabaseId)
REFERENCES CSCDatabase (Id)
GO
ALTER TABLE CSCWebLog CHECK CONSTRAINT FK1_CSCWebLog
GO
ALTER TABLE CSCWebLog  WITH CHECK ADD  CONSTRAINT FK2_CSCWebLog FOREIGN KEY(NodeId)
REFERENCES CSCFunction (FunctionId)
GO
ALTER TABLE CSCWebLog CHECK CONSTRAINT FK2_CSCWebLog
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCSession'AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE CSCSession
GO

CREATE TABLE CSCSession(
	DatabaseId    SMALLINT           NOT NULL,
	Id            VARCHAR(50)        NOT NULL,
    SeqNo         INT  IDENTITY(1,1) NOT NULL,
    SecOID        BIGINT,
    Start         DATETIME,
    [End]         DATETIME,
    FirstServerId INT,
    FirstHostId   INT,
    LoginId       INT,
    URLs          INT,
    Sent          BIGINT,
    Received      BIGINT,
    URLDuration   BIGINT	
 CONSTRAINT PK_CSCSession PRIMARY KEY CLUSTERED 
(
	DatabaseId ASC,
	Id         ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX IXBySeqNo ON CSCSession
(
	SeqNo ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCLogin'AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE CSCLogin
GO
CREATE TABLE CSCLogin(
	SeqNo           INT IDENTITY(1,1) NOT NULL Primary Key,
	Name            VARCHAR(255)      NOT NULL,
	UsersOID        BIGINT,
	OrganisationOID BIGINT,
	Type            VARCHAR(20)) ON [PRIMARY]
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCMissingSession'AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE CSCMissingSession
GO
CREATE TABLE CSCMissingSession(
	DatabaseId  SMALLINT NOT NULL,   
	SecOID      BIGINT   NOT NULL,
	AMSCreated  DATETIME,
	AMSModified DATETIME,
	SessionKey  VARCHAR(50),
	LoginId     INT,
	Created     DATETIME DEFAULT CURRENT_TIMESTAMP
 CONSTRAINT PK_CSCMissingSession PRIMARY KEY CLUSTERED 
(
	DatabaseId ASC,
	SecOID     ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCLongURL'AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE CSCLongURL
GO
CREATE TABLE CSCLongURL(
	Created     DATETIME DEFAULT CURRENT_TIMESTAMP,
	Updated     DATETIME DEFAULT CURRENT_TIMESTAMP,
	FirstSeqNo  BIGINT,
	URL	        VARCHAR(max),
	Count       INT) 
ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCURLHourlySummary'AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE CSCURLHourlySummary
GO
CREATE TABLE CSCURLHourlySummary(
	Timestamp     DATETIME NOT NULL,
    Year          AS DATEPART(yy, Timestamp),
    Month         AS DATEPART(mm, Timestamp),
    Day           AS DATEPART(dd, Timestamp),
    Hour          AS DATEPART(hh, Timestamp),
    WeekDay       AS LEFT(DATENAME(w, Timestamp), 3),
	DatabaseId    SMALLINT NOT NULL,
	EnvironmentId INT      NOT NULL,
	URLId         INT      NOT NULL,
	Method        CHAR     NOT NULL,
	Status        SMALLINT NOT NULL,
	ReferrerId    INT      NOT NULL,
	Count         INT,
	AvgSent       INT,
	AvgReceived   INT,
	AvgDuration   DECIMAL(19,6)
CONSTRAINT PK_CSCURLHourlySummary PRIMARY KEY CLUSTERED 
(
	Timestamp     ASC,
	DatabaseId    ASC,
	EnvironmentId ASC,
	URLId         ASC,
	Method        ASC,
	Status        ASC,
	ReferrerId    ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
