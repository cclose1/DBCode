DROP TABLE IF EXISTS Expenditure.User;

CREATE TABLE Expenditure.User (
  `UserId`           varchar(50) NOT NULL DEFAULT '',
  `Surname`          varchar(50) DEFAULT NULL,
  `Forname`          varchar(50) DEFAULT NULL,
  `Created`          datetime    DEFAULT NULL,
  `State`            varchar(20) DEFAULT NULL,
  `Salt`             varchar(50) DEFAULT NULL,
  `Password`         varchar(128) DEFAULT NULL,
  `LatestLogin`      datetime DEFAULT NULL,
  `Logins`           int DEFAULT 0,
  `LoginFails`       int DEFAULT 0,
  `ConsecutiveFails` int DEFAULT 0,
  `MaxLoginAttempts` int DEFAULT 3,
  `MaxIdleTime`      int DEFAULT 0,
  `SuspendTime`      int DEFAULT 15,
  PRIMARY KEY (`UserId`)
);

CREATE TRIGGER setcreated BEFORE INSERT ON User
FOR EACH ROW
  SET NEW.Created = CURRENT_TIMESTAMP();

INSERT Expenditure.User(UserId, Forname, Surname, MaxIdleTime) VALUES ('cclose', 'Chris', 'Close', 15);




