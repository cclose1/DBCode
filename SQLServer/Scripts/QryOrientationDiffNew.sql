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
		DFAvgDiastolic INT,
		PRIMARY KEY([Session], Side, Orientation))

INSERT @Measures(Session, Weekday, Side, Orientation, MNAvgSystolic, MNAvgDiastolic)
SELECT
	Session,
	Weekday,
	Side,
	ISNULL(Orientation, -1),
	AvgSystolic,
	AvgDiastolic
FROM MeasureSession 
WHERE Orientation IS NULL OR Orientation = 2
ORDER BY [Session], Side, Orientation

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
AND MN.Orientation = -1
AND MO.Orientation = 2

SELECT
	*
FROM @Measures
WHERE Orientation = -1
ORDER BY Session DESC