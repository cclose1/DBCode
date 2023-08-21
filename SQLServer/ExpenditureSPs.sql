USE Expenditure;

IF EXISTS (SELECT 0 FROM sys.synonyms WHERE name=N'WeekDayName')
	DROP SYNONYM dbo.WeekDayName
GO

CREATE SYNONYM dbo.WeekDayName FOR BloodPressure.dbo.WeekDayName
GO

IF EXISTS (SELECT 0 FROM sys.synonyms WHERE name=N'AppendSelectField')
	DROP SYNONYM dbo.AppendSelectField
GO

CREATE SYNONYM dbo.AppendSelectField FOR BloodPressure.dbo.AppendSelectField
GO

IF EXISTS (SELECT 0 FROM sys.synonyms WHERE name=N'SelectQuery')
	DROP SYNONYM dbo.SelectQuery
GO

CREATE SYNONYM dbo.SelectQuery FOR BloodPressure.dbo.SelectQuery
GO

IF EXISTS (SELECT 0 FROM sys.synonyms WHERE name=N'PrintSQL')
	DROP SYNONYM dbo.PrintSQL
GO

CREATE SYNONYM dbo.PrintSQL FOR BloodPressure.dbo.PrintSQL
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.UnitsToKwh') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.UnitsToKwh
GO

CREATE FUNCTION dbo.UnitsToKwh(@units AS DECIMAL(10,2), @calorificValue AS DECIMAL(10, 2) = 1.7)
RETURNS DECIMAL(10, 1)
AS 
BEGIN
	RETURN 1.02264 * @units * @calorificValue / 3.6
END
GO


IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.UnitsToKwhByDate') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.UnitsToKwhByDate
GO

CREATE FUNCTION UnitsToKwhByDate (@units AS DECIMAL(10,2), @date Date)
RETURNS DECIMAL(10, 2)
AS
BEGIN
	DECLARE @calVal AS DECIMAL(10, 3)
    
    SELECT  @calval = CalorificValue
	FROM Tariff
	WHERE  
		@Date >= Start
        AND (@Date < [End] OR [End] IS NULL)
        AND Name = 'SSEStd'
        AND Type = 'Gas';
        
	RETURN dbo.UnitsToKwh(@units, @calVal)
END
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'GetEnergyCosts' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'PROCEDURE')
	DROP PROCEDURE dbo.GetEnergyCosts
GO

CREATE PROCEDURE dbo.GetEnergyCosts(@start DATE, @end DATE, @printSQL AS CHAR = NULL)
AS
BEGIN
	DECLARE @fields  VARCHAR(max)
    DECLARE @whereCl VARCHAR(max)
	DECLARE @query   VARCHAR(max)
    DECLARE @nl      VARCHAR(3)

	SET @nl      = CHAR(13)
	SET @whereCL = CONCAT('Type <> ''Solar'' AND Start > ''', @start, '''')

    IF @end IS NOT NULL
	BEGIN
		SET @whereCl = CONCAT(@whereCl, ' AND Start <= ''', @end, '''');
	END

    EXEC AppendSelectField @fields OUTPUT, 'Type',                                      NULL,             NULL,         NULL
	EXEC AppendSelectField @fields OUTPUT, 'Start',                                     NULL,             'Start',      'Min'
    EXEC AppendSelectField @fields OUTPUT, 'dbo.WeekDayName(Min(Start))',               NULL,             'Weekday',    NULL
    EXEC AppendSelectField @fields OUTPUT, 'Start',                                     NULL,             '[End]',      'Max'
    EXEC AppendSelectField @fields OUTPUT, 'Days',                                      NULL,             'PeriodDays', 'Sum'
    EXEC AppendSelectField @fields OUTPUT, 'Datediff(Day, Min(Start), Max(Start))',     NULL,             'ActualDays', NULL
    EXEC AppendSelectField @fields OUTPUT, 'Count(*)',                                  NULL,             'Readings',   NULL
    EXEC AppendSelectField @fields OUTPUT, 'StartReading',                              NULL,              NULL,        'Min'
    EXEC AppendSelectField @fields OUTPUT, 'EndReading',                                NULL,              NULL,        'Max'
    EXEC AppendSelectField @fields OUTPUT, 'Kwh',                                       NULL,             'UsedKwh',    'Sum'
    EXEC AppendSelectField @fields OUTPUT, 'KwhCost',                                   'DECIMAL(10, 2)', 'KwhCost',    'Sum'
    EXEC AppendSelectField @fields OUTPUT, 'StdCost',                                   'DECIMAL(10, 2)', 'StdCost',    'Sum'
    EXEC AppendSelectField @fields OUTPUT, 'Sum(TotalCost)',                            'DECIMAL(10, 2)', 'Total',      NULL
	
	EXEC SelectQuery 'CostedReading', @fields, @whereCl, 'Type', 'Type'
END
GO
