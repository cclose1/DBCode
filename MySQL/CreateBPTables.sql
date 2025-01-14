USE BloodPressure;

DROP TABLE IF EXISTS Battery;

CREATE TABLE Battery(
	Date date        NOT NULL,
	Make varchar(50) NULL,
	PRIMARY KEY (Date ASC)
);

DROP TABLE IF EXISTS Measure;

CREATE TABLE Measure(
	Individual varchar(100)  NOT NULL,
	Session    datetime      NOT NULL,
	Timestamp  datetime      NOT NULL,
    Date       date          GENERATED ALWAYS AS (CAST(Timestamp AS Date)),
	Week       INT           GENERATED ALWAYS AS (Week(Timestamp) + 1),    
    WeekDay    VARCHAR(3)    GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
	Side       varchar(5)    NOT NULL,
	Systolic   int(3)        NULL,
	Diastolic  int(3)        NULL,
	Pulse      int(3)        NULL,
	Comment    varchar(1000) NULL,
	Orientation int           NULL,
	PRIMARY KEY (
		Individual ASC,
		Timestamp ASC)
);

DROP TABLE IF EXISTS MeasureABPM;

CREATE TABLE MeasureABPM(
	Individual varchar(100) NOT NULL,
	Timestamp  datetime     NOT NULL,
    Date       date         GENERATED ALWAYS AS (CAST(Timestamp AS Date)),
	Week       INT          GENERATED ALWAYS AS (Week(Timestamp) + 1),    
    WeekDay    VARCHAR(3)   GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
	Session    int          NOT NULL,
	Side       varchar(5)   NOT NULL,
	Systolic   int(3)       NULL,
	Diastolic  int(3)       NULL,
	Pulse      int(3)       NULL,
	MAP        int          NULL,
	PRIMARY KEY (
		Individual ASC,
		Timestamp ASC
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
DROP TABLE IF EXISTS Test;

CREATE TABLE Test(
	Timestamp  datetime     NOT NULL,
    Date       date         GENERATED ALWAYS AS (CAST(Timestamp AS Date)),
	Week       INT          GENERATED ALWAYS AS (Week(Timestamp) + 1),    
    WeekDay    VARCHAR(3)   GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3))
);
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(1, 'Seated Horizontal');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(2, 'Seated Vertical');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(3, 'Standing Horizontal');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(4, 'Standing Vertical');
INSERT INTO `BloodPressure`.`MeasureOrientation`(`Id`, `Orientation`) VALUES(5, 'Lying');

