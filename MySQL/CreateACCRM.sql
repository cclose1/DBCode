
DROP TABLE IF EXISTS PostCodes;

CREATE TABLE PostCodes(
	Code       varchar(15) NOT NULL PRIMARY KEY,
	CountyCode varchar(15),
	Latitude   float,
	Longitude  float
);
DROP TABLE IF EXISTS Service;

CREATE TABLE Service(
	Id   int         NOT NULL AUTO_INCREMENT PRIMARY KEY,
	Name varchar(50)
);

DROP TABLE IF EXISTS ContactType;

CREATE TABLE ContactType(
	Id   int         NOT NULL AUTO_INCREMENT PRIMARY KEY,
	Name varchar(50)
);

DROP TABLE IF EXISTS Address;

CREATE TABLE Address(
	Id       int           NOT NULL AUTO_INCREMENT,
	Start    datetime      NOT NULL,
	End      datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified datetime      NULL,
	Line1    varchar(100)  NOT NULL,
	Line2    varchar(100)  NULL,
	Line3    varchar(100)  NULL,
	Line4    varchar(100)  NULL,
	City     varchar(100)  NULL,
	County   varchar(100)  NULL,
	Country  varchar(100)  NULL,
	PostCode varchar(20)   NULL,
	PRIMARY KEY (Id, Start)
);

DELIMITER //

CREATE TRIGGER InsAddress BEFORE INSERT ON Address
FOR EACH ROW
BEGIN
	SET NEW.Start    = COALESCE(NEW.Start, NOW());
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//


CREATE TRIGGER UpdAddress BEFORE UPDATE ON Address
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Contact;

CREATE TABLE Contact(
	Id       int           NOT NULL AUTO_INCREMENT,
	Start    datetime      NULL,
	End      datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified datetime      NULL,
	Type     int           NOT NULL,
	Role     varchar(50)   NULL,
	Name     varchar(100)  NULL,
	Target   varchar(200),
	PRIMARY KEY (Id, Start)
);

DELIMITER //

CREATE TRIGGER InsContact BEFORE INSERT ON Contact
FOR EACH ROW
BEGIN
	SET NEW.Start    = COALESCE(NEW.Start, NOW());
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//


CREATE TRIGGER UpdContact BEFORE UPDATE ON Contact
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Provider;

CREATE TABLE Provider(
	Id       int           NOT NULL AUTO_INCREMENT,
	Start    datetime      NOT NULL,
	Name     varchar(50)   NOT NULL,
	End      datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified datetime      NULL,
	Comment  varchar(1000) NULL,
	PRIMARY KEY (Id, Start)
);

DELIMITER //

CREATE TRIGGER InsProvider BEFORE INSERT ON Provider
FOR EACH ROW
BEGIN
	SET NEW.Start    = COALESCE(NEW.Start, NOW());
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//
	
CREATE TRIGGER UpdProvider BEFORE UPDATE ON Provider
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Contacts;

CREATE TABLE Contacts(
	ProviderId int           NOT NULL,
	ContactId  int           NOT NULL,
	Start      datetime      NULL,
	End        datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified   datetime      NULL,
	Main       char(1)       DEFAULT 'Y',
	Comment    varchar(1000),
	PRIMARY KEY (ProviderId, ContactId, Start)
);

DELIMITER //

CREATE TRIGGER InsContacts BEFORE INSERT ON Contacts
FOR EACH ROW
BEGIN
	SET NEW.Start    = COALESCE(NEW.Start, NOW());
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//
	
CREATE TRIGGER UpdContacts BEFORE UPDATE ON Contacts
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Addresses;

CREATE TABLE Addresses(
	ProviderId int           NOT NULL,
	AddressId  int           NOT NULL,
	Start      datetime      NULL,
	End        datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified   datetime      NULL,
	Main       char(1)       DEFAULT 'Y',
	Comment    varchar(1000),
	PRIMARY KEY (ProviderId, AddressId, Start)
);

DELIMITER //

CREATE TRIGGER InsAddresses BEFORE INSERT ON Addresses
FOR EACH ROW
BEGIN
	SET NEW.Start    = COALESCE(NEW.Start, NOW());
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//
	
CREATE TRIGGER UpdAddresses BEFORE UPDATE ON Addresses
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Services;

CREATE TABLE Services(
	ProviderId int           NOT NULL,
	ServiceId  int           NOT NULL,
	Start      datetime      NULL,
	End        datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified   datetime      NULL,
	Comment    varchar(1000),
	PRIMARY KEY (ProviderId, ServiceId, Start)
);

DELIMITER //

CREATE TRIGGER InsServices BEFORE INSERT ON Services
FOR EACH ROW
BEGIN
	SET NEW.Start    = COALESCE(NEW.Start, NOW());
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//
	
CREATE TRIGGER UpdServices BEFORE UPDATE ON Services
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DROP TABLE IF EXISTS Coverage;

CREATE TABLE Coverage(
	Id          int           NOT NULL AUTO_INCREMENT,
	ProviderId  int           NOT NULL,
	Start       datetime      NULL,
	End         datetime      NULL DEFAULT '3000-01-01 00:00',
	Modified    datetime      NULL,
	PostCode    varchar(10),
	Distance    decimal(12, 2) NULL,
	Comment     varchar(1000),
	PRIMARY KEY (Id, ProviderId, Start)
);

DELIMITER //

CREATE TRIGGER InsCoverage BEFORE INSERT ON Coverage
FOR EACH ROW
BEGIN
	SET NEW.Start    = COALESCE(NEW.Start, NOW());
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//
	
CREATE TRIGGER UpdCoverage BEFORE UPDATE ON Coverage
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;

DELIMITER $$
DROP FUNCTION IF EXISTS DistanceBetween$$

CREATE FUNCTION DistanceBetween(
        lat1 FLOAT, lon1 FLOAT,
        lat2 FLOAT, lon2 FLOAT
     ) RETURNS FLOAT
    NO SQL DETERMINISTIC
    COMMENT 'Returns the distance in degrees on the Earth
             between two known points of latitude and longitude'
BEGIN
    RETURN 69*DEGREES(ACOS(
              COS(RADIANS(lat1)) *
              COS(RADIANS(lat2)) *
              COS(RADIANS(lon2) - RADIANS(lon1)) +
              SIN(RADIANS(lat1)) * SIN(RADIANS(lat2))
            ));
END$$

DELIMITER ;

DELIMITER $$
DROP FUNCTION IF EXISTS PostCodeDistance$$

CREATE FUNCTION PostCodeDistance(
        pc1 VARCHAR(20),
        pc2 VARCHAR(20)
     ) RETURNS FLOAT
    DETERMINISTIC
    COMMENT 'Returns the distance in degrees on the Earth
             between two known points of latitude and longitude'
BEGIN
	DECLARE lat1 FLOAT;
	DECLARE lon1 FLOAT;
	DECLARE lat2 FLOAT;
	DECLARE lon2 FLOAT;

	SELECT
		Latitude,
		Longitude
	INTO
		lat1,
		lon1
	FROM PostCodes
	WHERE Code = pc1;
	
	SELECT
		Latitude,
		Longitude
	INTO
		lat2,
		lon2
	FROM PostCodes
	WHERE Code = pc2;

	IF ISNULL(lat1) OR ISNULL(lon1) OR ISNULL(lat2) OR ISNULL(lon2) THEN RETURN NULL; END IF;

    RETURN DistanceBetween(lat1, lon1, lat2, lon2);
END$$

DELIMITER ;

DELIMITER $$
DROP FUNCTION IF EXISTS MilesPer1DegreeLongitude$$

CREATE FUNCTION MilesPer1DegreeLongitude(
        lat FLOAT
     ) RETURNS FLOAT
    DETERMINISTIC
    COMMENT 'Returns miles between 1 degree longitude at lat'
BEGIN
	RETURN cos(lat * PI() /180) * 2 * PI() * 3959 / 360;
END$$

DELIMITER ;