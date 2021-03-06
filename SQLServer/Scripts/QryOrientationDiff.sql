USE BloodPressure
DECLARE @Measures      AS TABLE(
		[Session]      DATETIME,
		Weekday        VARCHAR(20),
		Side           VARCHAR(10),
		Orientation    INT,
		MNAvgSystolic  INT,
		MNAvgDiastolic INT,
		MOAvgSystolic  INT,
		MOAvgDiastolic INT,
		DFAvgSystolic  INT,
		DFAvgDiastolic INT)

INSERT @Measures(Session, Weekday, Side, Orientation, MNAvgSystolic, MNAvgDiastolic)
SELECT
	Session,
	Weekday,
	Side,
	Orientation,
	AvgSystolic,
	AvgDiastolic
FROM MeasureSession 
WHERE Orientation IS NULL OR Orientation = 2

UPDATE MN
	SET 
		MOAvgSystolic  = MO.MNAvgSystolic,
		MOAvgDiastolic = MO.MNAvgDiastolic,
		DFAvgSystolic  = MO.MNAvgSystolic  - MN.MNAvgSystolic,
		DFAvgDiastolic = MO.MNAvgDiastolic - MN.MNAvgDiastolic
FROM @Measures MN
JOIN @Measures MO
ON  MN.Session = MO.Session
AND MN.Side    = MO.Side
AND MN.Orientation IS NULL
AND MO.Orientation = 2

SELECT
	*
FROM @Measures
WHERE Orientation IS NULL
ORDER BY Session DESC