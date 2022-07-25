DROP TABLE IF EXISTS Measure;

CREATE TABLE Measure(
	id          int           NOT NULL AUTO_INCREMENT,
	Individual  varchar(100)  NOT NULL,
	Session     datetime      NOT NULL,
	Timestamp   datetime      NOT NULL,
	Side        varchar(5)    NOT NULL,
	Systolic    int(3)        NULL,
	Diastolic   int(3)        NULL,
	Pulse       int(3)        NULL,
	Comment     varchar(1000) NULL,
	Orientation int           NULL,
	PRIMARY KEY (
		Individual ASC,
		Timestamp ASC,
		Side ASC)
);