USE BloodPressure
GO

DROP TABLE PostCodes
GO
CREATE TABLE PostCodes(
	Code         VARCHAR(15) NOT NULL,
	Start        DATE,
	[End]        DATE,
	CountyCode   VARCHAR(15) NULL,
	District     VARCHAR(15),
	Constituency VARCHAR(15),
	Ward         VARCHAR(15),
	PCT          VARCHAR(15), 
	CCG          VARCHAR(15),
	Latitude     FLOAT NULL,
	Longitude    FLOAT NULL,
	Easting      INT,
	Northing     INT
PRIMARY KEY CLUSTERED 
(
	Code ASC
))
GO
DROP TABLE OutboundPostCode
GO

CREATE TABLE OutboundPostCode(
	Area   VARCHAR(6),
	Code   VARCHAR(6)  NOT NULL,
	Town   VARCHAR(50) NOT NULL,
	County VARCHAR(50),
	Shared CHAR(1),
	NonGeo CHAR(1),
	Ignore CHAR(1)
PRIMARY KEY CLUSTERED 
(
	Code ASC,
	Town ASC
))
GO
DROP TABLE Ward
GO

CREATE TABLE Ward(
	Code VARCHAR(15) NOT NULL,
	Name VARCHAR(150)
PRIMARY KEY CLUSTERED 
(
	Code ASC
))
GO
DROP TABLE Constituency
GO

CREATE TABLE Constituency(
	Code VARCHAR(15) NOT NULL,
	Name VARCHAR(250)
PRIMARY KEY CLUSTERED 
(
	Code ASC
))
GO
DROP TABLE County
GO

CREATE TABLE County(
	Code   VARCHAR(15) NOT NULL,
	Number INT,
	Name   VARCHAR(250)
PRIMARY KEY CLUSTERED 
(
	Code ASC
))
GO
DROP TABLE District
GO

CREATE TABLE District(
	Code VARCHAR(15) NOT NULL,
	Name VARCHAR(150)
PRIMARY KEY CLUSTERED 
(
	Code ASC
))
GO
DROP VIEW ExpandedPostCodes
GO
CREATE VIEW [dbo].[ExpandedPostCodes]
AS
SELECT 
	PC.Code,
	Start,
	ISNULL(CT.Name, PC.CountyCode)             AS County,
	OP.Town                                    AS Town,
	DR.Name                                    AS District,
	CN.Name                                    AS Constituency,
	WD.Name                                    AS Ward,
	LEFT(PC.Code, CHARINDEX(' ', PC.Code) - 1) AS Outbound,
	PCT,
	CCG,
	Latitude,
	Longitude,
	Easting,
	Northing
  FROM PostCodes PC
  LEFT JOIN County  CT
  ON   PC.CountyCode = CT.Code
  LEFT JOIN District  DR
  ON   PC.District = DR.Code
  LEFT JOIN Constituency  CN
  ON   PC.Constituency = CN.Code
  LEFT JOIN Ward      WD
  ON   PC.Ward = WD.Code
  LEFT JOIN OutboundPostCode OP
  ON   LEFT(PC.Code, CHARINDEX(' ', PC.Code) - 1) = OP.Code
  AND  OP.Ignore IS NULL
  WHERE [End] IS NULL
GO

DROP VIEW OutboundSummary
GO
CREATE VIEW OutboundSummary
AS
SELECT
	County,
	Outbound,
	MIN(Town)        AS Town,
	MIN(Ward)        AS Ward,
	MIN(Latitude)    AS MinLatitude,
	MAx(Latitude)    AS MaxLatitude,
	MIN(Longitude)   AS MinLongitude,
	MAx(Longitude)   AS MaxLongitude,
	Count(*)         AS PostCodes,	
	ROUND(dbo.DistanceBetween(MIN(Latitude), MIN(Longitude), Min(Latitude), Max(Longitude)), 1) AS Width,
	ROUND(dbo.DistanceBetween(MIN(Latitude), MIN(Longitude), Max(Latitude), Min(Longitude)), 1) AS Height,
	ROUND(dbo.DistanceBetween(MIN(Latitude), MIN(Longitude), Max(Latitude), Max(Longitude)), 1) AS Diag
FROM BloodPressure.dbo.ExpandedPostCodes
GROUP BY County, Outbound
