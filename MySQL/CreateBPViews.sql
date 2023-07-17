DROP VIEW IF EXISTS MeasureTry;

CREATE VIEW MeasureTry
AS
SELECT
	Individual,
    Session,
	Timestamp,
	CAST(Timestamp AS Date)                           AS Date,
	CAST(Timestamp AS Time)                           AS Time,
	Year(Timestamp)                                   AS Year,
	Month(Timestamp)                                  AS Month,
	Day(Timestamp)                                    AS Day,
	Week(Timestamp) + 1                               AS Week,
	SubStr(DayName(Timestamp), 1, 3)                  AS Weekday,
	WeekStart(Timestamp)                              AS WeekStart,
	Side,
	Rank() OVER (Partition By Individual, Session, Side Order By Timestamp ASC) AS Try,
	Systolic,
	Diastolic,
	Pulse,
    Systolic - Diastolic                              AS PulsePressure,
    GetStage(Systolic, Diastolic, 'N')                AS Stage,
    GetStage(Systolic, Diastolic, 'Y')                AS NICEStage,
	Orientation
FROM BloodPressure.Measure;

DROP VIEW IF EXISTS MeasureSession;

CREATE VIEW MeasureSession
AS
SELECT
	Individual,
    Min(Year)          AS Year,
	Min(Date)          AS Date,
	Min(Time)          AS Time,
	Session,
	Min(Weekday)       AS Weekday,
	Side,
	Orientation,
	COUNT(*)           AS Tries,
	Min(Systolic)      AS MinSystolic,
	Min(Diastolic)     AS MinDiastolic,
	Min(Pulse)         AS MinPulse,
	MIN(PulsePressure) AS MinPulsePressure,
	Avg(Systolic)      AS AvgSystolic,
	Avg(Diastolic)     AS AvgDiastolic,
	Avg(Pulse)         AS AvgPulse,
	Avg(PulsePressure) AS AvgPulsePressure,
	Max(Systolic)      AS MaxSystolic,
	Max(Diastolic)     AS MaxDiastolic,
	Max(Pulse)         AS MaxPulse,
	Max(PulsePressure) AS MaxPulsePressure
FROM MeasureTry
GROUP BY Individual, Session, Side, Orientation;

	