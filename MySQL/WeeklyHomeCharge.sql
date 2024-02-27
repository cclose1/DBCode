SELECT
    YEAR(Start)                                         AS Year,
	WEEK(Start, 1)                                      AS Week,
    Count(*)                                            AS Sessions,
	MIN(Start)                                          AS Start,
    SUM(EndPerCent - StartPercent)                      AS PercentGain,
    SUM(Charge)                                         AS Charge,
    SUM(EndPerCent - StartPercent) * Car.Capacity / 100 AS EstCharge,
    SUM(Cost)                                           AS Cost
FROM Expenditure.Chargesession CS
JOIN Expenditure.Car 
ON   Car.Registration = CS.CarReg
WHERE CarReg = 'EO70 ECC'
AND   Charger = 'HomePodPoint'
GROUP BY Year(Start), WEEK(Start, 1)
ORDER BY YEAR(Start) DESC, WEEK(Start, 1) DESC;

