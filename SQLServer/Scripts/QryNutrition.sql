/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 
	*
  FROM [BloodPressure].[dbo].[NutritionEventsDaily]
--  WHERE Weekday = 'Sun'
  ORDER BY Date DESC
  
SELECT
	*
FROM BloodPressure.dbo.NutritionEventsWeekly
ORDER BY WeekStart DESC
