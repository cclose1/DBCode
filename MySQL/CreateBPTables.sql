DROP TABLE IF EXISTS Battery;

CREATE TABLE Battery(
	Date date        NULL,
	Make varchar(50) NULL,
	PRIMARY KEY (Date ASC)
);

DROP TABLE IF EXISTS Measure;

CREATE TABLE Measure(
	Individual  nchar(100)    NOT NULL,
	Session     datetime      NOT NULL,
	Timestamp   datetime      NOT NULL,
	Side        varchar(5)    NOT NULL,
	Systolic    int           NULL,
	Diastolic   int           NULL,
	Pulse       int           NULL,
	Comment     varchar(1000) NULL,
	Orientation int           NULL,
	PRIMARY KEY (
		Individual ASC,
		Timestamp ASC,
		Side ASC)
);

DROP TABLE IF EXISTS MeasureABPM;

CREATE TABLE MeasureABPM(
	Individual nchar(100) NOT NULL,
	Timestamp  datetime   NOT NULL,
	Session    int        NOT NULL,
	Side       varchar(5) NOT NULL,
	Systolic   int        NULL,
	Diastolic  int        NULL,
	Pulse      int        NULL,
	MAP int NULL,
	PRIMARY KEY (
		Individual ASC,
		Timestamp ASC,
		Side ASC
	)
);



DROP TABLE IF EXISTS DrugHistory;

CREATE TABLE DrugHistory(
	Drug      varchar(50) NOT NULL,
	Start     datetime    NOT NULL,
	End       datetime    NOT NULL,
	DailyDose float       NULL,
	PRIMARY KEY (
		Start ASC,
		Drug  ASC)
);

DROP TABLE IF EXISTS MeasureOrientation;

CREATE TABLE MeasureOrientation(
	Id          smallint    NOT NULL,
	Orientation varchar(50) NULL,
	PRIMARY KEY (
		Id ASC)
);

INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(1, 'Seated Horizontal');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(2, 'Seated Vertical');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(3, 'Standing Horizontal');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(4, 'Standing Vertical');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(5, 'Lying');
