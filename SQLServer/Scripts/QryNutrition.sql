SELECT Count(*) FROM NutritionRecord
/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 1000 [Year]
      ,[Month]
      ,[Day]
      ,[Date]
      ,[Weekday]
      ,[Calories]
      ,[Protein]
      ,[Fat]
      ,[Saturated]
      ,[Carbohydrate]
      ,[Sugar]
      ,[Fibre]
      ,[Cholesterol]
      ,[Salt]
      ,[Units]
      ,[Kilos]
      ,CAST(Kilos / 2.89 AS DECIMAL(6, 2)) AS BMI
      , 4 * (Carbohydrate + Protein) + 9 * Fat + 56 * ISNULL(units, 0) AS CalculateCalories
      ,Round(Calories/8, 1) DRVCarb
      ,Round(0.35 * Calories / 9, 1) AS DRVFat
  FROM [BloodPressure].[dbo].[NutritionEventsDaily]
--  WHERE Weekday = 'Sun'
  ORDER BY Date DESC
  
SELECT
	Days * 2500 - Calories AS Remaining,
	*,
	Round(DailyCalories/8, 1) DRVCarb,
	Round(0.35 * DailyCalories / 9, 1) AS DRVFat,
	Round(4 *(DailyCarbohydrate + DailyProtein) + DailyFat * 9 + 56 * DailyUnits, 1) AS EstimatedCalories
FROM BloodPressure.dbo.NutritionEventsWeeklyNew
ORDER BY Date DESC
