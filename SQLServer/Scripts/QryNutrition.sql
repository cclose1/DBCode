/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000
	*
  FROM [BloodPressure].[dbo].[NutritionEventsDaily]
--WHERE Weekday = 'Sun'-- OR Weekday = 'Sat'


  ORDER BY Date DESC

SELECT
	*
FROM BloodPressure.dbo.NutritionEventsWeekly
ORDER BY WeekStart DESC

SELECT BloodPressure.dbo.BMI(69.5, NULL)

SELECT 44900.0/245