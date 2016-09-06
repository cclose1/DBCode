USE BloodPressure
GO
IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'SubstituteComposite' AND type ='p')
BEGIN
	DROP Procedure dbo.SubstituteComposite
END
GO
CREATE PROCEDURE SubstituteComposite(
		@Item          AS VARCHAR(50), 
		@source        AS VARCHAR(50), 
		@timestamp     AS DATETIME = NULL,
		@matchQuantity AS CHAR     = 'Y',
		@update        AS CHAR     = 'N',
		@display       AS CHAR     = 'Y')
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @sql        AS NVARCHAR(max)
	DECLARE @columns    AS NVARCHAR(max)
	DECLARE @allowIdent AS CHAR
	DECLARE @inserts    AS INT
	DECLARE @deletes    AS INT
	
	CREATE TABLE #Composite (
		Name      VARCHAR(50),
		Source    VARCHAR(50),
		Start     DATETIME,
		[End]     DATETIME,
		Record    DATETIME,
		IName     VARCHAR(50),
		ISource   VARCHAR(50),
		IQuantity DECIMAL(12, 2))
	CREATE TABLE #Items (
		Timestamp   DATETIME,
		Name        VARCHAR(50),
		[Index]     INT,
		Source      VARCHAR(50),
		Quantity    DECIMAL(12, 2),
		CmpQuantity DECIMAL(12, 2),
		Complete    CHAR(1))
	
	INSERT #Composite 
	SELECT
		NC.Item,		
		NC.Source,
		NC.Start,
		NC.[End],
		NC.Record,
		NR.Item,
		NR.Source,
		NR.Quantity
	FROM NutritionComposite NC
	JOIN NutritionRecord    NR
	ON NC.Record    = NR.Timestamp
	WHERE NC.Item   = @Item
	AND   NC.Source = @source
	AND	  NR.Timestamp BETWEEN NC.Start AND NC.[End]
	
	INSERT #Items
	SELECT
		NR.Timestamp,
		NR.Item,
		ROW_NUMBER() OVER(PARTITION BY Timestamp ORDER BY Name),
		NR.Source,
		NR.Quantity,
		CM.IQuantity,
		'N'
	FROM #Composite CM
	JOIN NutritionRecord NR
	ON  CM.IName     = NR.Item
	AND CM.ISource   = NR.Source
	AND NR.Timestamp <> CM.Record
	WHERE (@timestamp IS NULL OR NR.Timestamp >= @timestamp)
	AND   (COALESCE(@matchQuantity, 'N') = 'N' OR @matchQuantity = 'Y' AND CM.IQuantity = NR.Quantity)
	UPDATE #Items
		SET Complete = 'Y'
	WHERE Timestamp IN (
	SELECT 
		Timestamp 
	FROM (
		SELECT 
			Timestamp,
			COUNT(*) AS Count 
		FROM #Items 
		GROUP BY Timestamp) J1
	WHERE Count = (SELECT COUNT(*) FROM #Composite))
	
	IF @display = 'Y'
	BEGIN
		SELECT * FROM #Composite
		SELECT 
			IT.*,
			NE.Description 
		FROM #Items  IT
		LEFT JOIN NutritionEvent NE
		ON IT.Timestamp = NE.Timestamp
		WHERE Complete = 'Y'
		ORDER BY Timestamp, Name
	
		SELECT
			*
		FROM NutritionRecord NR
		JOIN #Items          IT
		ON  NR.Timestamp = IT.Timestamp
		AND NR.Item      = IT.Name
		AND NR.Source    = IT.Source
		WHERE Complete = 'Y'
		SET @deletes = @@ROWCOUNT
		
		SELECT
			IT.Timestamp,
			CM.Name,
			CM.Source,
			1         AS Quantity,
			NULL      AS ABV,
			'Y'       AS IsComposite,
			Description
		FROM #Composite CM
		JOIN #Items     IT
		ON  CM.IName   = IT.Name
		AND CM.ISource = IT.Source
		AND Complete   = 'Y'
		AND IT.[Index] = 1
		LEFT JOIN NutritionEvent NE
		ON IT.Timestamp = NE.Timestamp
		SET @inserts = @@ROWCOUNT
	END
	
	IF @update = 'Y'
	BEGIN
		DELETE NR
		FROM NutritionRecord NR
		JOIN #Items          IT
		ON  NR.Timestamp = IT.Timestamp
		AND NR.Item      = IT.Name
		AND NR.Source    = IT.Source
		WHERE Complete = 'Y'	
		SET @deletes = @@ROWCOUNT
		
		INSERT NutritionRecord(Timestamp, Item, Source, Quantity, ABV, IsComposite)
		SELECT
			IT.Timestamp,
			CM.Name,
			CM.Source,
			1         AS Quantity,
			NULL      AS ABV,
			'Y'       AS IsComposite
		FROM #Composite CM
		JOIN #Items     IT
		ON  CM.IName   = IT.Name
		AND CM.ISource = IT.Source
		AND Complete   = 'Y'
		AND IT.[Index] = 1
		SET @inserts = @@ROWCOUNT
	END
	
	PRINT 'Deletes ' + CAST(@deletes AS VARCHAR) + ' inserts ' + CAST(@inserts AS VARCHAR)
END
