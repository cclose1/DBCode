DROP TABLE IF EXISTS NutritionSources;

CREATE TABLE NutritionSources(
	Name     varchar(50) NOT NULL PRIMARY KEY,
	Created  datetime    NULL
);

DELIMITER //

CREATE TRIGGER InsNutritionSources BEFORE INSERT ON NutritionSources
FOR EACH ROW
BEGIN
	SET NEW.Created = COALESCE(NEW.Created, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS NutritionTypes;

CREATE TABLE NutritionTypes(
	Name     VARCHAR(50) NOT NULL PRIMARY KEY,
	Created  DATETIME    NULL
);

DELIMITER //

CREATE TRIGGER InsNutritionTypes BEFORE INSERT ON NutritionTypes
FOR EACH ROW
BEGIN
	SET NEW.Created = COALESCE(NEW.Created, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS NutritionDetail;

CREATE TABLE NutritionDetail(
	Item         varchar(50)   NOT NULL,
	Source       varchar(50)   NOT NULL,
	Start        datetime      NOT NULL,
	Type         varchar(10)   NULL,
	End          datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified     datetime      NULL,
	Calories     decimal(6, 2) NULL,
	Protein      decimal(5, 2) NULL,
	Fat          decimal(5, 2) NULL,
	Saturated    decimal(5, 2) NULL,
	Carbohydrate decimal(5, 2) NULL,
	Sugar        decimal(5, 2) NULL,
	Fibre        decimal(5, 2) NULL,
	Cholesterol  decimal(5, 2) NULL,
	Salt         decimal(5, 2) NULL,
	DefaultSize  decimal(6, 2) NULL,
	ABV          decimal(4, 1) NULL,
	Simple       char(1)       NULL,
	PackSize     decimal(6, 1) NULL,
  PRIMARY KEY (Item, Source, Start)
);

DELIMITER //

CREATE TRIGGER InsNutritionDetail BEFORE INSERT ON NutritionDetail
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdNutritionDetail BEFORE UPDATE ON NutritionDetail
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS NutritionComposite;

CREATE TABLE NutritionComposite(
	Item          VARCHAR(50) NOT NULL,
	Source        VARCHAR(50) NOT NULL,
	Start         DATETIME,
	Type          VARCHAR(10),
	End           DATETIME DEFAULT '3000-01-01 00:00',
	Modified      DATETIME,
	Record        DATETIME,
	PRIMARY KEY (Item, Source, Start)
);

DELIMITER //

CREATE TRIGGER InsNutritionComposite BEFORE INSERT ON NutritionComposite
FOR EACH ROW
BEGIN
	IF NEW.Start = 0 THEN SET NEW.Start = NOW(); END IF;
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//


CREATE TRIGGER UpdNutritionComposite BEFORE UPDATE ON NutritionComposite
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;
DROP TABLE IF EXISTS NutritionEvent;

CREATE TABLE NutritionEvent(
	Timestamp   datetime      NOT NULL,
	Modified    datetime      NULL,
	Description varchar(100)  NULL,
	Comment     varchar(1000) NULL,
	PRIMARY KEY (Timestamp));


DELIMITER //

CREATE TRIGGER InsNutritionEvent BEFORE INSERT ON NutritionEvent
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdNutritionEvent BEFORE UPDATE ON NutritionEvent
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS NutritionRecord;

CREATE TABLE NutritionRecord(
	Timestamp   datetime      NOT NULL,
	Item        varchar(50)   NOT NULL,
	Source      varchar(50)   NOT NULL,
	Modified    datetime      NULL,
	Quantity    decimal(6, 2) NULL,
	ABV         decimal(4, 1) NULL,
	IsComposite char(1),
	PRIMARY KEY (Timestamp, Item, Source));


DELIMITER //

CREATE TRIGGER InsNutritionRecord BEFORE INSERT ON NutritionRecord
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdNutritionRecord BEFORE UPDATE ON NutritionRecord
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Weight;

CREATE TABLE Weight(
	Date  date       NOT NULL,
	Time  time           NULL,
	Kilos numeric(10, 2) NULL,
	PRIMARY KEY(Date ASC));

DROP TABLE IF EXISTS NutritionHistorical;

CREATE TABLE NutritionHistorical(
	Timestamp    datetime    NOT NULL,
	Weight       decimal(12, 2)  NULL,
	Description  varchar(50)     NULL,
	Calories     decimal(12, 3)  NULL,
	Protein      decimal(12, 3)  NULL,
	Fat          decimal(12, 3)  NULL,
	Saturated    decimal(12, 3)  NULL,
	Carbohydrate decimal(12, 3)  NULL,
	Sugar        decimal(12, 3)  NULL,
	Fibre        decimal(12, 3)  NULL,
	Cholesterol  decimal(12, 3)  NULL,
	Salt         decimal(12, 3)  NULL,
	Units        decimal(12, 3)  NULL,
	PRIMARY KEY(Timestamp));
