   
DROP VIEW IF EXISTS BoundedReadingOld;

CREATE VIEW BoundedReadingOld AS
SELECT
	J1.Timestamp                         AS Start,
    J1.Type,
    J1.Estimated                         AS StartEstimated,
    J1.Weekday,
    J2.Timestamp                         AS 'End',
    J2.Estimated                         AS EndEstimated,
    DATEDIFF(J2.Timestamp, J1.Timestamp) AS Days,
    J1.Reading                           AS StartReading,
    J2.Reading                           AS EndReading,
    J1.SeqNo,
    J2.Reading - J1.Reading              AS ReadingChange,
    CASE J1.Type
      WHEN 'Gas' THEN 
        UnitsToKwh(J2.TruncReading - J1.TruncReading, TR.CalorificValue)
      ELSE 
		J2.TruncReading - J1.TruncReading
      END AS Kwh,
    J1.Tariff,
    TR.UnitRate,
    TR.StandingCharge,
    TR.CalorificValue,
    J1.Comment
FROM (
	SELECT 
		Timestamp,
        Weekday,
        Type,
        Tariff,
        Reading,
        Estimated,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Type ORDER BY Timestamp) AS SeqNo,
        Comment
	FROM MeterReading) AS J1
JOIN (
	SELECT 
		Timestamp,
        Type,
        Tariff,
        Reading,
        Estimated,
        TRUNCATE(Reading, 0)                                     AS TruncReading,
		ROW_NUMBER() OVER (PARTITION BY Type ORDER BY Timestamp) AS SeqNo
	FROM MeterReading) AS J2
	ON J1.SeqNo = J2.SeqNo - 1
	AND J1.Type = J2.Type
LEFT JOIN Tariff  TR 
ON   J1.Timestamp >=  TR.Start 
AND (J1.Timestamp < TR.End OR TR.End IS NULL)
AND TR.Code = J1.Tariff
AND TR.Type = J1.Type;

DROP TABLE IF EXISTS MeterReadingOld;

CREATE TABLE MeterReadingOld (
	Timestamp DATETIME       NOT NULL,
    WeekDay   VARCHAR(3)     GENERATED ALWAYS AS (SUBSTR(DAYNAME(Timestamp), 1, 3)),
	Type      VARCHAR(15)    NOT NULL,
	Tariff    VARCHAR(15)    NOT NULL DEFAULT 'SSEStd',
	Modified  DATETIME       NULL,
	Reading   DECIMAL(10, 2) NULL,
    Estimated CHAR(1)        NULL,
	Comment   VARCHAR(1000),
	PRIMARY KEY (Timestamp, Type)
);

DELIMITER //

CREATE TRIGGER InsMeterReadingOld BEFORE INSERT ON MeterReading
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

CREATE TRIGGER UpdMeterReadingOld BEFORE UPDATE ON MeterReadingOld
FOR EACH ROW
BEGIN
	SET NEW.Modified = COALESCE(NEW.Modified, NOW());
END;//

DELIMITER ;