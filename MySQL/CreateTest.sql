USE Expenditure;

DROP TABLE IF EXISTS Test;

CREATE TABLE Test (
    Name       VARCHAR(10)   NOT NULL,
	Start      DATETIME      NOT NULL,
	End        DATETIME      NULL,
    Date       DATE          NULL,
    Time       Time          NULL,
	Modified   DATETIME      NULL,
	Dec1       DECIMAL(9, 5) NULL,
	Dec2       DECIMAL(6, 2) NOT NULL,
	Int01	   INT(7)        NOT NULL,
	Int02	   INT(4)        NULL,
    Real1      REAL          NULL,
    Char10     CHAR(10)      NULL,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Name ASC, Start ASC)
); 
DELIMITER //

CREATE TRIGGER InsTest BEFORE INSERT ON Test
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdTest BEFORE UPDATE ON Test
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

INSERT INTO `expenditure`.`test`
(`Name`,
`Start`,
`End`,
`Date`,
`Time`,
`Dec1`,
`Dec2`,
`Int01`,
`Int02`,
`Real1`,
`Char10`,
`Comment`)
VALUES
('Name1', '2020-11-01 10:30', NULL, '2020-12-08', '12:03', 12.4, 100.9, 31, 133, 17.45, 'Abcde', 'A comment');

DROP TABLE IF EXISTS Test2;

CREATE TABLE Test2 (
    Network    VARCHAR(15)   NOT NULL,
    Location   VARCHAR(15)   NOT NULL,
	Modified   DATETIME      NULL,
    Text21     VARCHAR(15)   NULL,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Network ASC, Location ASC)
); 
DELIMITER //

CREATE TRIGGER InsTest2 BEFORE INSERT ON Test2
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdTest2 BEFORE UPDATE ON Test2
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

INSERT INTO Test2 (Network, Location, Text21, Comment)
VALUES 
('PodPoint', 'Home2p3Kw',    'Text1',  'Tst21Comment'),
('PodPoint', 'HomePodpoint', 'Text4',  'Tst22Comment'),
('TestNet1', 'Home2p3Kw',    'Text7',  'Tst23Comment'),
('TestNet1', 'HomePodpoint', 'Text0',  'Tst23Comment')
;
DROP TABLE IF EXISTS Test3;

CREATE TABLE Test3 (
    Network    VARCHAR(15)   NOT NULL,
    Location   VARCHAR(15)   NOT NULL,
    Name       VARCHAR(15)   NOT NULL,
	Modified   DATETIME      NULL,
    Text1      VARCHAR(15)   NULL,
    Text2      VARCHAR(15)   NOT NULL,
	Dec1       DECIMAL(9, 5) NULL,
	Dec2       DECIMAL(6, 2) NOT NULL,
	Int01	   INT(7)        NULL,
	Int02	   INT(4)        NOT NULL,
    Char10     CHAR(10)      NULL,
	Comment    VARCHAR(1000),
	PRIMARY KEY (Network ASC, Location ASC, Name ASC)
); 
DELIMITER //

CREATE TRIGGER InsTest3 BEFORE INSERT ON Test3
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdTest3 BEFORE UPDATE ON Test3
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

INSERT INTO Test3 (Network, Location, Name, Text1, Text2, Dec1, Dec2, Int01, Int02, Char10, Comment)
VALUES 
('PodPoint', 'Home2p3Kw',    'TstName1', 'Text1',  'Text1M', 10.01, 10.02, 1001, 1002, 'Char101', 'Tst1Comment'),
('PodPoint', 'Home2p3Kw',    'TstName2', 'Text2',  'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst2Comment'),
('PodPoint', 'Home2p3Kw',    'TstName3', 'Text3',  'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst3Comment'),
('PodPoint', 'HomePodpoint', 'TstName1', 'Text4',  'Text1M', 10.01, 10.02, 1001, 1002, 'Char101', 'Tst1Comment'),
('PodPoint', 'HomePodpoint', 'TstName2', 'Text5',  'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst2Comment'),
('PodPoint', 'HomePodpoint', 'TstName3', 'Text6',  'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst3Comment'),
('TestNet1', 'Home2p3Kw',    'TstName1', 'Text7',  'Text1M', 10.01, 10.02, 1001, 1002, 'Char101', 'Tst1Comment'),
('TestNet1', 'Home2p3Kw',    'TstName2', 'Text8',  'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst2Comment'),
('TestNet1', 'Home2p3Kw',    'TstName3', 'Text9',  'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst3Comment'),
('TestNet1', 'HomePodpoint', 'TstName1', 'Text10', 'Text1M', 10.01, 10.02, 1001, 1002, 'Char101', 'Tst1Comment'),
('TestNet1', 'HomePodpoint', 'TstName2', 'Text11', 'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst2Comment'),
('TestNet1', 'HomePodpoint', 'TstName3', 'Text12', 'Text2M', 11.01, 11.02, 102, 102,   'Char102', 'Tst3Comment')
;