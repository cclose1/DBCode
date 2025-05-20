USE Expenditure;

DROP FUNCTION IF EXISTS UnitsToKwh;

DELIMITER $$

CREATE FUNCTION UnitsToKwh (Units  DECIMAL(10,3), CalorificValue DECIMAL(10,3))
	RETURNS DECIMAL(10, 3)
	DETERMINISTIC
BEGIN
	RETURN 1.02264 * Units * CalorificValue / 3.6;
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS KwhToUnits;

DELIMITER $$

CREATE FUNCTION KwhToUnits (Kwh DECIMAL(10,3), CalorificValue DECIMAL(10,3))
	RETURNS DECIMAL(10, 3)
	DETERMINISTIC
BEGIN
	RETURN 3.6 * Kwh / CalorificValue / 1.02264;
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS GetCalorificValue;

DELIMITER $$

CREATE FUNCTION GetCalorificValue (Date Date)
	RETURNS DECIMAL(10, 3) DETERMINISTIC
BEGIN
	DECLARE CalVal DECIMAL(10, 3);
    
    SELECT 
		Value INTO Calval
	FROM BoundedCalorificValue
	WHERE  
		Date >= Start
        AND (Date < End OR End IS NULL);
        
	RETURN CalVal;
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS UnitsToKwhByDate;

DELIMITER $$

CREATE FUNCTION UnitsToKwhByDate (Units  DECIMAL(10,3), Date Date)
	RETURNS DECIMAL(10, 3) DETERMINISTIC
BEGIN
	DECLARE CalVal DECIMAL(10, 3);
    
    SELECT 
		Value INTO Calval
	FROM BoundedCalorificValue
	WHERE  
		Date >= Start
        AND (Date < End OR End IS NULL);
        
	RETURN UnitsToKwh(Units, CalVal);
END$$

DELIMITER ;
DROP FUNCTION IF EXISTS KwhToUnitsByDate;

DELIMITER $$

CREATE FUNCTION KwhToUnitsByDate (Kwh DECIMAL(10,3), Date Date)
	RETURNS DECIMAL(10, 3) DETERMINISTIC
BEGIN
	DECLARE CalVal DECIMAL(10, 3);
    
    SELECT 
		Value INTO Calval
	FROM BoundedCalorificValue
	WHERE  
		Date >= Start
        AND (Date < End OR End IS NULL);
        
	RETURN KwhToUnits(Kwh, CalVal);
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS GetEnergyCosts;

DELIMITER $$

CREATE PROCEDURE GetEnergyCosts(
	IN Start DATE,
    IN End   DATE)
BEGIN
	DECLARE Fields    VARCHAR(10000); 
    DECLARE WhereCl   VARCHAR(1000) DEFAULT CONCAT("Type <> 'Solar' AND Start > '", Start, "'");
    
    IF End IS NOT NULL THEN
		SET WhereCl = CONCAT(WhereCl, " AND Start <= '", End, "'");
	END IF;
    
    CALL BloodPressure.AddSelectField(Fields, 'Type',                              NULL,             NULL,             NULL);
    CALL BloodPressure.AddSelectField(Fields, 'Start',                             NULL,             'Start',          'Min');
    CALL BloodPressure.AddSelectField(Fields, 'SUBSTR(DAYNAME(Min(Start)), 1, 3)', NULL,             'Weekday',        NULL);
    CALL BloodPressure.AddSelectField(Fields, 'Start',                             NULL,             'End',            'Max');
    CALL BloodPressure.AddSelectField(Fields, 'Days',                              NULL,             'PeriodDays',     'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'Datediff(Max(End), Min(Start))',    NULL,             'ActualDays',     NULL);
    CALL BloodPressure.AddSelectField(Fields, 'Count(*)',                          NULL,             'Readings',       NULL);
    CALL BloodPressure.AddSelectField(Fields, 'StartReading',                      NULL,              NULL,            'Min');
    CALL BloodPressure.AddSelectField(Fields, 'EndReading',                        NULL,              NULL,            'Max');
    CALL BloodPressure.AddSelectField(Fields, 'Kwh',                               NULL,             'UsedKwh',        'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'PeakKwh',                           NULL,             'PeakKwh',        'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'OffPeakKwh',                        NULL,             'OffPeakKwh',     'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'KwhCost',                           'DECIMAL(10, 2)', 'KwhCost',        'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'PeakKwhCost',                       'DECIMAL(10, 2)', 'PeakKwhCost',    'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'OffPeakKwhCost',                    'DECIMAL(10, 2)', 'OffPeakKwhCost', 'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'StdCost',                           'DECIMAL(10, 2)', 'StdCost',        'Sum');
    CALL BloodPressure.AddSelectField(Fields, 'Sum(TotalCost)',                    'DECIMAL(10, 2)', 'Total',          NULL);
    
    SET @Query = CONCAT(
		'SELECT \n\r', Fields, 
        '\n\rFROM CostedReading', 
        '\n\rWhere ', WhereCl, 
        '\n\rGroup By Type', 
        '\n\rOrder By Type');
    PREPARE STMT FROM @Query; 
    EXECUTE STMT; 
    DEALLOCATE PREPARE STMT;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS GetCarUsageSummary;

DELIMITER $$

CREATE PROCEDURE GetCarUsageSummary(Period VARCHAR(10), WhereAnd VARCHAR(1000))
BEGIN
	DECLARE Fields    VARCHAR(10000); 
    DECLARE GroupBy   VARCHAR(1000); 
    DECLARE OrderBy   VARCHAR(1000) DEFAULT '';
    DECLARE WhereCl   VARCHAR(1000) DEFAULT "CarReg = 'EO70 ECC'";
    DECLARE Message   VARCHAR(1000);
    
    CALL BloodPressure.AddPeriodGroup(Period, GroupBy, Fields, OrderBy, 'DESC', Message);
    
    IF WhereAnd IS NOT NULL AND WhereAnd <> '' Then
		SET WhereCl = CONCAT(WhereCl, ' AND ', WhereAnd);
	END IF;
        
	CALL BloodPressure.AddSelectField(Fields, 'Count(*)', NULL,    'Sessions', NULL);
    CALL BloodPressure.AddAggregateField(Fields, 'Start',       'Min-');
    CALL BloodPressure.AddAggregateField(Fields, 'Cost',        'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'Charge',      'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'UseCharge',   'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'EstCharge',   'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'UsedMiles',   'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'UsedPercent', 'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'UsedCharge',  'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'HomeCost',    'Sum-');
    CALL BloodPressure.AddAggregateField(Fields, 'PetrolCost',  'Sum-');
    SET @Query = CONCAT(
		'SELECT \n\r', Fields, 
        '\n\rFROM Expenditure.SessionUsage', 
        '\n\rWhere ', WhereCl, 
        '\n\rGroup By ', GroupBy, 
        '\n\rOrder By ', OrderBy);
        
    PREPARE STMT FROM @Query; 
    EXECUTE STMT; 
    DEALLOCATE PREPARE STMT;
END$$

DELIMITER ;