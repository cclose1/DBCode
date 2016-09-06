IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCServer' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCServer
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCDeployment' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCDeployment
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCEnvironment' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCEnvironment
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCRelease' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCRelease
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCFunction' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCFunction
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCDatabase' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCDatabase
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCText' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCText
GO
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = N'CSCFrequentText' AND TABLE_SCHEMA = 'dbo' AND TABLE_TYPE=N'BASE TABLE')
 DROP TABLE dbo.CSCFrequentText
GO

/****** Object:  Table [pe].[CSCFunction]    Script Date: 03/09/2009 13:18:21 ******/

CREATE TABLE dbo.CSCText(
	Id     INT          IDENTITY(1,1) NOT NULL,
	Value  VARCHAR(890)               NOT NULL
 CONSTRAINT PK_CSCText PRIMARY KEY CLUSTERED 
(
    Id     ASC,
    Value  ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX IDX1_CSCText ON dbo.CSCText
(
	Value ASC,
	Id    ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE TABLE dbo.CSCFrequentText(
	Id     INT          IDENTITY(1,1) NOT NULL,
	Value  VARCHAR(890)               NOT NULL
 CONSTRAINT PK_CSCFrequentText PRIMARY KEY CLUSTERED 
(
    Id     ASC,
    Value  ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX IDX1_CSCFrequentText ON dbo.CSCFrequentText
(
	Value ASC,
	Id    ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
GO

CREATE TABLE dbo.CSCDatabase(
	Id         smallint IDENTITY(1,1) NOT NULL,
	Name       varchar(255)           NOT NULL,
	Server     sysname                NULL,
	[Database] sysname                NOT NULL,
	[Schema]   sysname                NOT NULL DEFAULT 'dbo',
	[Current]  char                   NOT NULL DEFAULT 'Y',
	Comment    varchar(1024)          NULL
 CONSTRAINT PK_CSCDatabase PRIMARY KEY NONCLUSTERED 
(
    Id     ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

CREATE TABLE dbo.CSCFunction(
	FunctionId int IDENTITY(1,1) NOT NULL,
	Type       varchar(20)       NOT NULL, 
	Name       varchar(255)      NOT NULL,
	Usage      varchar(30)       NOT NULL DEFAULT ('New'),
	URLPath    AS CASE WHEN Type='ASP Page' THEN [dbo].[GetPrefix]([Name],'/') ELSE NULL END,
	URLName    AS CASE WHEN Type='ASP Page' THEN [dbo].[GetSuffix]([Name],'/') ELSE NULL END,
	URLType    AS CASE WHEN Type='ASP Page' THEN [dbo].[GetSuffix]([Name],'.') ELSE NULL END,
	Version    varchar(20)       NULL,
	Node       char              NULL,
	PerfNode   char              NULL,
	Stack      char              NULL,
	WebLog     char              NULL,
	Discovered datetime          NOT NULL CONSTRAINT DF_CSCFunction_Discovered DEFAULT (getdate()),
	Ignore     char              NOT NULL CONSTRAINT DF_CSCFunction_Ignore     DEFAULT ('N')
 CONSTRAINT PK_CSCFunction PRIMARY KEY CLUSTERED 
(
    FunctionId  ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
CREATE UNIQUE NONCLUSTERED INDEX IDX1_CSCFunction ON dbo.CSCFunction
(
	Name       ASC,
	Version    ASC,
	Type       ASC,
	FunctionId ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]

CREATE NONCLUSTERED INDEX IDX2_CSCFunction ON dbo.CSCFunction
(
	Type    ASC,
	Version ASC)
INCLUDE 
(
	FunctionId,
	Name,
	Discovered
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]


CREATE TABLE dbo.CSCRelease(
	ReleaseId   varchar(50)  NOT NULL,
	Date        datetime     NOT NULL,
	Description varchar(255) NULL,
 CONSTRAINT PK_CSCRelease PRIMARY KEY CLUSTERED 
(
	ReleaseId ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
CREATE TABLE dbo.CSCEnvironment(
	Environment         varchar(50)    NOT NULL,
	EnvironmentId       int            IDENTITY(1,1) NOT NULL,
	Description         varchar(200)   NULL,
    Ignore              char           NOT NULL DEFAULT 'N',
	MinNodeCount        int            NOT NULL DEFAULT 100,
	MinNodeDuration     decimal(19, 2) NOT NULL DEFAULT 1.5,
	MaxNodeDuration     decimal(19, 2) NOT NULL DEFAULT 20,
	MinFunctionCount    int            NOT NULL DEFAULT 100,
	MinFunctionDuration decimal(19, 2) NOT NULL DEFAULT 0.5,
	MaxFunctionDuration decimal(19, 2) NOT NULL DEFAULT 20
 CONSTRAINT PK_CSCEnvironment PRIMARY KEY CLUSTERED 
(
	Environment ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

CREATE TABLE dbo.CSCServer(
    SeqNo       int          IDENTITY(1,1) NOT NULL,
	Name        varchar(180) NOT NULL,
	Type		varchar(30)  NOT NULL DEFAULT 'Presentation',
	Environment varchar(50)  NOT NULL DEFAULT 'UNKNOWN',
	ManIP       varchar(50)  NULL,
    ProdIP      varchar(50)  NULL,
    Tower       varchar(10)  NULL,
    Ignore      char(1)      NULL DEFAULT 'N',
	Deployed    datetime     NOT NULL,
	Removed     datetime     NULL,
 CONSTRAINT PK_CSCServer PRIMARY KEY CLUSTERED 
(
	SeqNo       ASC,
	Deployed    ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]
GO
ALTER TABLE dbo.CSCServer WITH CHECK ADD  CONSTRAINT [FK1_CSCServer] FOREIGN KEY(Environment)
REFERENCES  dbo.CSCEnvironment (Environment)
GO
CREATE TABLE dbo.CSCDeployment(
	ReleaseId   varchar(50) NOT NULL,
	Environment varchar(50) NOT NULL,
	Deployed    datetime    NOT NULL,
	Removed     datetime    NULL,
CONSTRAINT PK_CSCDeployed PRIMARY KEY CLUSTERED 
(
	ReleaseId   ASC,
	Environment ASC,
	Deployed    ASC
)WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
ALTER TABLE dbo.CSCDeployment  WITH CHECK ADD  CONSTRAINT FK1_CSCReleaseDeployed FOREIGN KEY(ReleaseId)
REFERENCES dbo.CSCRelease (ReleaseId)
GO
ALTER TABLE dbo.CSCDeployment CHECK CONSTRAINT FK1_CSCReleaseDeployed
GO