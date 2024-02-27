
SELECT * 
  FROM BloodPressure.NutritionEventsDaily
  WHERE Substring(dayname(curdate()), 1, 3) = Weekday
  -- WHERE Weekday = 'Fri'
  ORDER BY Date DESC;

SELECT
	*
FROM BloodPressure.NutritionEventsWeekly
ORDER BY WeekStart DESC 