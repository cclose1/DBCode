DELETE FROM Expenditure.CarChargeParams WHERE EndPercent = 100;

INSERT Expenditure.CarChargeParams(StartPerCent, EndPerCent, Kwh, Duration, Sessions)
SELECT 
	StartPerCent,
    Avg(EndPerCent)  AS EndPerCent,
    Avg(charge)      AS Kwh,
    Avg(ChargeHours) AS Duration,
    Count(*)         AS Sessions
FROM expenditure.chargesessionanalysis
WHERE StartPercent > 90
AND   EndPerCent = 100
AND   ChargeDuration IS not NULL
Group BY StartPerCent
ORDER BY StartPerCent;

INSERT Expenditure.CarChargeParams(StartPerCent, EndPerCent, Kwh, Duration, Sessions)
VALUES
(93, 100, 6, 1.0, 0),
(96, 100, 4, 0.8, 0),
(98, 100, 2, 0.5, 0);

SELECT 
	*
FROM expenditure.CarChargeParams;