-- Weekly Home Charge

SELECT
    YEAR(Start)                                         AS Year,
	WEEK(Start, 1)                                      AS Week,
    Count(*)                                            AS Sessions,
	MIN(Start)                                          AS Start,
	MAX(Start)                                          AS End,
    SUM(EndPerCent - StartPercent)                      AS PercentGain,
    SUM(Charge)                                         AS Charge,
    SUM(EndPerCent - StartPercent) * Car.Capacity / 100 AS EstCharge,
    SUM(Cost)                                           AS Cost,
    100 * SUM(Cost) / SUM(EndPerCent - StartPercent)    AS FullCost
FROM Expenditure.Chargesession CS
JOIN Expenditure.Car 
ON   Car.Registration = CS.CarReg
WHERE CarReg = 'EO70 ECC'
AND   Charger = 'HomePodPoint'
GROUP BY Year(Start), WEEK(Start, 1)
ORDER BY YEAR(Start) DESC, WEEK(Start, 1) DESC;

-- TempTrace summary.

SELECT 
	TM.*,
    J2.Cost,
    J2.Mileage                                AS Mileage,
    J2.Mileage - J1.Mileage                   AS Miles,
    100 * J2.Cost / (J2.Mileage - J1.Mileage) AS CostPerMile
FROM expenditure.temptrace TM
JOIN  (
	SELECT 
		ROW_NUMBER () OVER (ORDER BY CarReg, Start) Num,
		CarReg,
        Cost,
        Start,
		Mileage
    FROM Expenditure.MergedSession) AS J1
    JOIN (
		SELECT 
			ROW_NUMBER () OVER (ORDER BY CarReg, Start) Num,
            CarReg,
            Start,
            Cost,
            Mileage
		FROM Expenditure.MergedSession) AS J2
    ON  J1.CarReg = J2.CarReg
    AND J1.Num    = J2.num - 1
ON TM.SessionStart = J2.Start
ORDER BY SessionStart DESC;

-- Home charge session 100% durations

SELECT 
	*,
    Charge / PercentGain,
    60 * percentGain / ChargeDurationMinutes AS chPerHr,
    ChargeDurationMinutes / PercentGain AS MinPerPercent,
    ChargeDurationMinutes - EstDuration AS EstDifference
FROM Expenditure.SessionChargeDetails
WHERE Charger    = 'HomePodPoint' 
AND   EndPercent = 100 
AND   StartPercent < 99
AND   DurationCalculated = 'N'
ORDER BY StartPercent DESC;

SELECT 
	*,
    60 * percentGain / ChargeDurationMinutes AS chPerHr,
    ChargeDurationMinutes / PercentGain AS MinPerPercent,
    ChargeDurationMinutes - EstDuration AS EstDifference
FROM expenditure.sessionchargedetails
WHERE Charger      = 'HomePodPoint' 
AND   EndPercent   < 97
-- AND   StartPercent < 99 
AND   DurationCalculated = 'N'
ORDER BY StartPercent DESC;

-- Check Meter OffPeak


SELECT 
	TMP.*,
    MR.OffPeakKwh AS MtrOffPeak
FROM (
	SELECT
		*
	FROM expenditure.meterreading 
	WHERE Meter LIKE 'Elec%' ) MR
JOIN (
	SELECT 
		MeterStart,
		Count(*) AS Sessions,
		Sum(Kwh) AS Kwh,
		Sum(OpKwh) AS OpKwh
	FROM expenditure.temptrace
	WHERE MeterStart IS NOT NULL
	GROUP BY MeterStart) TMP
ON MR.Timestamp = TMP.MeterStart
 WHERE OpKwh <> OffPeakKwh
ORDER BY MeterStart DESC;

-- NHS Home Blood Pressure Data.

SELECT 
	DATE_FORMAT(BM.Date, "%d/%m/%Y") AS Date,
    FirstSession,
    LastSession,
    BM.WeekDay,
    BM.Session,
    BM.Timestamp,
    BM.Systolic,
    BM.Diastolic,
    BM.Pulse
FROM (
	SELECT 
		*
	FROM (
		SELECT
			Date,
            Min(Session) AS FirstSession,
            Max(Session) AS LastSession,
			Min(WeekDay),
			Count(*) AS Measures
		FROM Bloodpressure.Measure
		WHERE Side = 'Left' AND Orientation IS NULL
		GROUP BY Date) J1
	JOIN ( 
		SELECT
			Date AS DateS,
			Session, 
			Max(Timestamp) AS Timestamp, 
			Count(*) AS SessionMeasures 
		FROM bloodpressure.measure 
		WHERE Side = 'Left' AND Orientation IS NULL
		GROUP BY Date, Session) J2
		ON J1.Date = J2.DateS
	WHERE Measures = 9) J3
	JOIN BloodPressure.Measure BM
	ON J3.Timestamp = BM.Timestamp
    AND Hour(FirstSession) < 10
    AND Hour(LastSession)  > 17
    AND (FirstSession = BM.Session || LastSession = BM.Session)
	ORDER BY BM.Date DESC;
    
-- Usage by Week and Peek

SELECT 
	YEAR(Date),
    MIN(Date)     AS Date,
    Week,
    Type,
    Peak,
    COUNT(*) / 24 AS Days,
    SUM(Reading)  AS Reading
FROM expenditure.smartmeterhourlydata
GROUP BY YEAR(Date), Week, Type, Peak
ORDER BY MIN(Date) DESC, Type;


-- Usage by Week

SELECT 
	YEAR(Date),
    MIN(Date)     AS Date,
    Week,
    Type,
    COUNT(*) / 24 AS Days,
    SUM(Reading)  AS Reading
FROM expenditure.smartmeterhourlydata
GROUP BY YEAR(Date), Week, Type
ORDER BY MIN(Date) DESC, Type;

-- Oxford cash spend

SELECT
	Year,
    Week,
    Payment,
    Min(Timestamp) AS Timestamp,
    Sum(Amount)    AS Spend
FROM expenditure.spend 
WHERE (WeekDay = 'Wed' OR WeekDay = 'Thu' AND Time < '16:00') AND Payment = 'Cash'
GROUP BY Year, Week, Payment
ORDER BY Min(Timestamp) DESC;

-- ChargeSessionStats

SELECT
	CS.Start,
    CS.EndPerCent,
    CS.EndPerCent - CS.StartPerCent AS Gain,
    Kwh,
    OpKwh,
    Charge,
    CS.Cost,
    OpDerivation,
    OpKwhFromCost,
    OpKwhFromRatio,
    OpKwhFromApprox,
    Round(100 * CS.Cost / (CS.EndPerCent - CS.StartPerCent), 2) AS CostPerPercent,
    Round(100 / (CS.EndPerCent - CS.StartPerCent) * Kwh, 2) AS FullCharge
FROM expenditure.chargesessionstats TT
JOIN expenditure.chargesession CS
ON TT.SessionStart = CS.Start
AND TT.MeterStart IS NOT NULL
ORDER BY CS.Start DESC