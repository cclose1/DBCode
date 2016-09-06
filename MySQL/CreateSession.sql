DROP TABLE IF EXISTS `Session`;

CREATE TABLE `Session` (
  `SeqNo` int(11) NOT NULL AUTO_INCREMENT,
  `SessionId` Varchar(50) NOT NULL,
  `UserId` varchar(50) DEFAULT NULL,
  `Start` datetime DEFAULT NULL,
  `State` varchar(20) DEFAULT NULL,
  `End` datetime DEFAULT NULL,
  `Last` datetime DEFAULT NULL,
  `Accesses` int DEFAULT 0,
  `Deadlocks` int DEFAULT 0,
  `Host` varchar(200) DEFAULT NULL,
  `Origin` varchar(200) DEFAULT NULL,
  `Protocol` varchar(200) DEFAULT NULL,
  `Referrer` varchar(200) DEFAULT NULL,
  PRIMARY KEY (`SeqNo`),
  UNIQUE (`SessionId`)
) ENGINE=InnoDB AUTO_INCREMENT=1832 DEFAULT CHARSET=utf8;

CREATE TRIGGER setstartdate BEFORE INSERT ON Session
FOR EACH ROW
  SET NEW.Start = CURRENT_TIMESTAMP();

