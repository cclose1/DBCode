/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [Individual]
--      ,[Year]
      ,[Week]
      ,[Side]
      ,[Try]
      ,[Date]
      ,[Measures]
--      ,[FirstSession]
      ,[LastSession]
      ,[MinSystolic]
      ,[MinDiastolic]
      ,[MinPulse]
      ,[MinPulsePressure]
      ,[AvgSystolic]
      ,[AvgDiastolic]
      ,StdSystolic
      ,StdDiastolic
      ,[AvgPulse]
      ,[AvgPulsePressure]
      ,[MaxSystolic]
      ,[MaxDiastolic]
      ,[MaxPulse]
      ,[MaxPulsePressure]
      ,DH.DailyDose
  FROM [BloodPressure].[dbo].[MeasureWeeklyTry] WT
  LEFT JOIN [BloodPressure].[dbo].DrugHistory DH
  ON WT.Date BETWEEN DH.Start AND DH.[End]
  WHERE Individual = 'ANON'
  AND   Side       = 'Left'
  AND   Try        IN (3)
 -- AND Try <= 3
--   AND  (AvgSystolic >= 150 OR AvgDiastolic >= 95)
  ORDER BY Date DESC, Side, Try DESC
  
  -- 4	Left	1	2015-01-18	33	2015-01-24 11:45:32	122	80	50	42	148	88	60	60	178	98	78	93
  -- 4	Left	2	2015-01-18	33	2015-01-24 11:45:32	118	78	50	38	145	89	61	56	169	101	82	71
  -- 4	Left	3	2015-01-18	25	2015-01-24 08:24:16	115	79	53	36	139	87	63	51	165	101	82	64
  
 