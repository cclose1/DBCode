USE BloodPressure;

DROP TABLE Battery
GO
CREATE TABLE Battery(
	Date Date        NOT NULL DEFAULT GETDATE(),
	Make VARCHAR(50) NULL,
	PRIMARY KEY (Date ASC)
)

DROP TABLE Measure;

CREATE TABLE Measure(
	Individual  VARCHAR(100)  NOT NULL DEFAULT 'ANON',
	Date        AS CONVERT(Date, Session,(0)),
	Week        AS DATEPART(WEEK, Session),
	Weekday     AS SUBSTRING(DATENAME(WEEKDAY, Session),(1),(3)),
	Session     DATETIME      NOT NULL,
	Timestamp   DATETIME      NOT NULL,
	Side        VARCHAR(5)    NOT NULL,
	Systolic    DECIMAL(3, 0) NULL,
	Diastolic   DECIMAL(3, 0) NULL,
	Pulse       DECIMAL(3, 0) NULL,
	Comment     VARCHAR(MAX)  NULL,
	Orientation int           NULL,
	PRIMARY KEY (
		Individual ASC,
		Timestamp ASC)
)
GO
DROP TABLE MeasureABPM
GO
CREATE TABLE MeasureABPM(
	Individual  VARCHAR(100) NOT NULL,
	Date        AS CONVERT(Date, Timestamp,(0)),
	Week        AS DATEPART(WEEK, Timestamp),
	Weekday     AS SUBSTRING(DATENAME(WEEKDAY, Timestamp),(1),(3)),
	Timestamp   DATETIME      NOT NULL,
	Session     INT           NOT NULL,
	Side        VARCHAR(5)    NOT NULL,
	Systolic    DECIMAL(3, 0) NULL,
	Diastolic   DECIMAL(3, 0) NULL,
	Pulse       DECIMAL(3, 0) NULL,
	MAP         INT           NULL,
	PRIMARY KEY (
		Individual ASC,
		Timestamp ASC
	)
)
GO
DROP TABLE DrugHistory
GO
CREATE TABLE DrugHistory(
	Drug      VARCHAR(50) NOT NULL,
	Start     DATETIME    NOT NULL,
	[End]     DATETIME    NOT NULL,
	DailyDose FLOAT       NULL,
	PRIMARY KEY (
		Start ASC,
		Drug  ASC)
)
GO
DROP TABLE MeasureOrientation
GO
CREATE TABLE MeasureOrientation(
	Id          SMALLINT    NOT NULL,
	Orientation VARCHAR(20) NULL,
	PRIMARY KEY (
		Id ASC)
)
GO
INSERT INTO MeasureOrientation(Id, Orientation) VALUES(1, 'Seated Horizontal')
INSERT INTO MeasureOrientation(Id, Orientation) VALUES(2, 'Seated Vertical')
INSERT INTO MeasureOrientation(Id, Orientation) VALUES(3, 'Standing Horizontal')
INSERT INTO MeasureOrientation(Id, Orientation) VALUES(4, 'Standing Vertical')
INSERT INTO MeasureOrientation(Id, Orientation) VALUES(5, 'Lying')
