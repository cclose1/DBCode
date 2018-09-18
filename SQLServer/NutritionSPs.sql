USE BloodPressure

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.BMI') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.BMI
GO

CREATE FUNCTION dbo.BMI(@kilos AS DECIMAL(10,2), @height AS DECIMAL(10, 2) = 1.7)
RETURNS DECIMAL(6, 1)
AS 
BEGIN
    RETURN @kilos / SQUARE(ISNULL(@height, 1.7))
END
GO
IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.CalculateCalories') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.CalculateCalories
GO

CREATE FUNCTION dbo.CalculateCalories(@fat AS DECIMAL(8, 3) = NULL, @carb AS DECIMAL(8, 3), @protein AS DECIMAL(8, 3) = NULL, @units AS DECIMAL(8, 3) = NULL)
RETURNS DECIMAL(8, 3)
AS 
BEGIN
    RETURN 4 * (ISNULL(@carb, 0) + ISNULL(@protein, 0)) + 9 * ISNULL(@fat, 0) + 56 * ISNULL(@units, 0)
END
GO

IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'dbo.WeekStart') and OBJECTPROPERTY(id, N'IsScalarFunction') = 1)
	DROP FUNCTION dbo.WeekStart
GO

CREATE FUNCTION dbo.WeekStart(@day AS DATE)
RETURNS DATE
AS 
BEGIN
    RETURN CAST(DATEADD(D, -DATEPART(w, @day) + 1, @day) AS DATE)
END