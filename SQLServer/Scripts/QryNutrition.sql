/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000
	*
  FROM [BloodPressure].[dbo].[NutritionEventsDaily]
--WHERE Weekday = 'Sun'-- OR Weekday = 'Sat'

--WHERE Weekday = SUBSTRING(DATENAME(WEEKDAY,GETDATE()),(1),(3))

  ORDER BY Date DESC

SELECT
	*
FROM BloodPressure.dbo.NutritionEventsWeekly
ORDER BY WeekStart DESC





