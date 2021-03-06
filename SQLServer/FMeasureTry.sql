
IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME = N'FMeasureTry' AND ROUTINE_SCHEMA = 'dbo' AND ROUTINE_TYPE = N'FUNCTION')
	DROP FUNCTION dbo.FMeasureTry
GO

CREATE FUNCTION dbo.FMeasureTry(@sessionGap AS INT)
	RETURNS @measure TABLE (
				Individual  VARCHAR(100),
				Side        VARCHAR(10),
				Session     DATETIME,
				Timestamp   DATETIME,
				Systolic    INT,
				Diastolic   INT,
				Pulse       INT,
				Gap         INT,
				Try         INT,
				Orientation INT,
				Comment     VARCHAR(max))
AS
BEGIN
	DECLARE @lTry        AS INT = 0
	DECLARE @rTry        AS INT = 0
	DECLARE @gap         AS INT = 0
	DECLARE @lIndividual AS VARCHAR(100)
	DECLARE @lTime       AS DATETIME
	DECLARE @session     AS DATETIME
	
	DECLARE measure CURSOR LOCAL FAST_FORWARD 
	FOR 
	SELECT 
		Individual,
		Side,
		Timestamp,
		Systolic,
		Diastolic,
		Pulse,
		Orientation,
		Comment		
	FROM Measure WITH (NOLOCK)
	ORDER BY Individual, Timestamp
	
	OPEN measure
	
	WHILE 0 = 0
	BEGIN
		DECLARE @individual  AS VARCHAR(100)
		DECLARE @side        AS VARCHAR(5)
		DECLARE @timestamp   AS DATETIME
		DECLARE @systolic    AS INT
		DECLARE @diastolic   AS INT
		DECLARE @pulse       AS INT
		DECLARE @orientation AS INT
		DECLARE @comment     AS VARCHAR(max)
		
		FETCH NEXT FROM measure INTO @individual, @side, @timestamp, @systolic, @diastolic, @pulse, @orientation, @comment

		IF @@fetch_status <> 0 BREAK
		
		SET @gap = DATEDIFF(S, @lTime, @timestamp)
		
		IF @individual <> @lIndividual OR @gap IS NULL OR @gap >= @sessionGap
		BEGIN
			SET @lTry    = 0
			SET @rTry    = 0
			SET @session = @timestamp
		END
		
		IF @side = 'LEFT'  SET @lTry += 1
		IF @side = 'RIGHT' SET @rTry += 1
		
		INSERT INTO @measure
		VALUES (
			@individual,
			@side,
			@session,
			@timestamp,
			@systolic,
			@diastolic,
			@pulse,
			@gap,
			CASE WHEN @side = 'LEFT' THEN @lTry ELSE @rTry END,
			@orientation,
			@comment)
		SET @lTime       = @timestamp
		SET @lIndividual = @individual
	END
	RETURN
END
