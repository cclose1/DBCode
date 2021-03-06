
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'Server') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE Server 
GO

CREATE TABLE Server(
	Id         INT IDENTITY(1,1) NOT NULL,
	Server     VARCHAR(50) NULL,
	Discovered DATETIME    NULL,
	Active     CHAR(1)     NULL,
 CONSTRAINT PK_Server PRIMARY KEY CLUSTERED 
(
	Id ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'Load') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE Load 
GO

CREATE TABLE Load(
	Id INT IDENTITY(1,1) NOT NULL,
	Start         DATETIME NULL,
	Duration      FLOAT    NULL,
	ActiveServers INT      NULL,
	LoadedServers INT      NULL,
	Lines         INT      NULL,
	Files         INT      NULL,
	Deleted       INT      NULL,
	Errored       INT      NULL,
	NotFound      INT      NULL,
	FatalError    CHAR(1)  NULL,
	Errors        INT      NULL,
	Reload        CHAR(1)  NULL,
	DBSize        FLOAT    NULL,
	DBAdded       FLOAT    NULL,
	DBFree        FLOAT    NULL,
 CONSTRAINT PK_Load PRIMARY KEY CLUSTERED 
(
	Id ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'LogLoad') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE LogLoad 
GO

CREATE TABLE LogLoad(
	ServerId  INT         NOT NULL,
	[File]    VARCHAR(20) NOT NULL,
	DataDate  DATETIME    NULL,
	Run       INT         NULL,
	Loads     INT         NULL,
	LastLoad  DATETIME    NULL,
	Reload    CHAR(1)     NULL,
	Lines     INT         NULL,
	Errors    INT         NULL,
	TotalTime FLOAT       NULL,
	BCPTime   FLOAT       NULL,
 CONSTRAINT PK_LogLoad PRIMARY KEY CLUSTERED 
(
	ServerId ASC,
	[File]   ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'WebLog') AND OBJECTPROPERTY(id, N'IsUserTable') = 1)
 DROP TABLE WebLog 
GO

CREATE TABLE WebLog(
	SeqNo     numeric(18, 0) IDENTITY(1,1)                  NOT NULL,
	Host      varchar(128)                                  NOT NULL,
	Server    varchar(128)                                      NULL,
	[File]    varchar(20)                                       NULL,
	Timestamp datetime                                          NULL,
	Method    varchar(10)                                       NULL,
	URIStem   varchar(max) COLLATE SQL_Latin1_General_CP1_CS_AS NULL,
	URIQuery  varchar(max) COLLATE SQL_Latin1_General_CP1_CS_AS NULL,
	Username  varchar(128)                                      NULL,
	IP        varchar(64)                                       NULL,
	Cookie    varchar(max)                                      NULL,
	Referrer  varchar(max) COLLATE SQL_Latin1_General_CP1_CS_AS NULL,
	Status    int                                               NULL,
	SubStatus int                                               NULL,
	Sent      int                                               NULL,
	Received  int                                           NOT NULL,
	Duration  int                                               NULL,
 CONSTRAINT [PK_WebLog] PRIMARY KEY NONCLUSTERED
(
	SeqNo ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

IF  EXISTS (SELECT * FROM sys.triggers WHERE object_id = OBJECT_ID(N'trigInsertWebLog'))
DROP TRIGGER trigInsertWebLog
GO

SET ANSI_PADDING OFF
GO
CREATE TRIGGER trigInsertWebLog
ON WebLog 
FOR INSERT
AS
INSERT Host (Identifier, Type, Discovered)
SELECT I.Host, 'Unknown', min(I.Timestamp)
FROM      INSERTED I
LEFT JOIN Host     H
ON        I.Host = H.Identifier
WHERE H.Identifier IS NULL
GROUP BY I.Host
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'LatestServerLoad' AND TABLE_TYPE=N'VIEW')
 DROP VIEW LatestServerLoad
GO

CREATE VIEW LatestServerLoad
AS
SELECT Id, 
       Server,
       Active,
       DataDate, 
       LL.[File], 
       LastLoad, 
       Lines
FROM Server SV
LEFT OUTER JOIN (SELECT ServerId, 
                        MAX([File]) AS [File]
                 FROM LogLoad 
                 GROUP BY ServerId) LL
ON SV.Id = LL.ServerId
LEFT OUTER JOIN LogLoad LG
ON  LG.ServerId = Id
AND LG.[File]   = LL.[File]