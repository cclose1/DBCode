USE BloodPressure;

DROP FUNCTION IF EXISTS BMI;

DELIMITER $$

CREATE FUNCTION BMI (kilos  DECIMAL(10,2))
RETURNS DECIMAL(6, 1)
DETERMINISTIC
BEGIN
    RETURN kilos / 2.89;
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS CalculateCalories;

DELIMITER $$


CREATE FUNCTION CalculateCalories(fat DECIMAL(8, 3), carb DECIMAL(8, 3), protein DECIMAL(8, 3), units DECIMAL(8, 3))
RETURNS DECIMAL(8, 3)
DETERMINISTIC
BEGIN
    RETURN 4 * (IFNULL(carb, 0) + IFNULL(protein, 0)) + 9 * IFNULL(fat, 0) + 56 * IFNULL(units, 0);
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS WeekStart;

DELIMITER $$

CREATE FUNCTION WeekStart(day DATE)
RETURNS DATE
DETERMINISTIC
BEGIN
    RETURN CAST(DATE_ADD(day, INTERVAL -dayofweek(day) + 1 DAY) AS DATE);
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS WeekDayName;

DELIMITER $$

CREATE FUNCTION WeekDayName(day DATE)
RETURNS VARCHAR(3)
DETERMINISTIC
BEGIN
    RETURN (SUBSTR(DAYNAME(Timestamp), 1, 3));
END$$

DELIMITER ;

DROP FUNCTION IF EXISTS GetStage;

DELIMITER $$

CREATE FUNCTION GetStage (systolic INT, diastolic INT, isNICE CHAR)
RETURNS VARCHAR(10)
DETERMINISTIC
BEGIN
	DECLARE Result VARCHAR(10) DEFAULT 'Normal';
	IF isNICE = 'Y'
    THEN
		IF     systolic >= 180 OR diastolic >= 110 THEN RETURN '3';
		ELSEIF systolic >= 155 OR diastolic >= 95  THEN RETURN '2';
		ELSEIF systolic >= 135 OR diastolic >= 85  THEN RETURN '1';
		ELSEIF systolic >= 120 OR diastolic >= 80  THEN RETURN 'Pre';
        END IF;
	ELSE
		IF     systolic >= 180 OR diastolic >= 110 THEN RETURN '3';
		ELSEIF systolic >= 160 OR diastolic >= 100 THEN RETURN '2';
		ELSEIF systolic >= 140 OR diastolic >= 90  THEN RETURN '1';
		ELSEIF systolic >= 120 OR diastolic >= 80  THEN RETURN 'Pre';
        END IF;
	END IF;
	
	RETURN 'Normal';
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS Append;

DELIMITER $$

CREATE PROCEDURE Append(
	INOUT String VARCHAR(10000),
    IN    Field  VARCHAR(1000),
    IN    Sep    VARCHAR(2))
BEGIN    
	IF (String IS NULL OR String = '') THEN
		SET String = Field;
	ELSE
		IF Sep IS NOT NULL THEN SET String = CONCAT(String, SEP); END IF;
		SET String = CONCAT(String, Field);
	END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS AddSelectField;

DELIMITER $$

CREATE PROCEDURE AddSelectField(
	INOUT String VARCHAR(10000),
    IN    Field  VARCHAR(1000),
    IN    CastCl VARCHAR(1000),
    IN    Alias  VARCHAR(1000),
    IN    Aggr   VARCHAR(20))
BEGIN
	DECLARE inField VARCHAR(1000);

    SET inField = Field;
    
	IF Aggr IS NOT NULL THEN
		SET Field = CONCAT(Aggr, '(', Field, ')');
        
        IF Alias IS NULL THEN
			SET Alias = CONCAT(Aggr, inField);
		END IF;
    END IF;
    
    IF CastCl IS NOT NULL AND CastCL <> '' THEN
		SET Field = CONCAT('Cast(', Field, ' AS ', CastCL, ')');
        
        IF Alias IS NULL THEN
			SET Alias = inField;
		END IF;
    END IF;
    
    CALL Append(String, Field, ',\n\r');
    
    IF Alias IS NOT NULL THEN
		CALL Append(String, CONCAT(' AS ', Alias), NULL);
	END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS AddGroupField;

DELIMITER $$

CREATE PROCEDURE AddGroupField(
    IN    Field     VARCHAR(1000),
	INOUT GroupBy   VARCHAR(10000),
	INOUT Fields    VARCHAR(10000),
	INOUT OrderBy   VARCHAR(10000),
    IN    Direction VARCHAR(20))
BEGIN
	CALL Append(GroupBy, Field, ',');
	CALL Append(Fields,  Field, ',\n\r');
    
    IF OrderBy IS NOT NULL THEN
		CALL Append(OrderBy, Field, ',');
        
        IF Direction IS NOT NULL AND Direction <> '' THEN
			CALL Append(OrderBy, Direction, ' ');
		END IF;
    END IF;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS AddAggregateField;

DELIMITER $$

CREATE PROCEDURE AddAggregateField(
	INOUT Fields     VARCHAR(10000),
    IN    Field      VARCHAR(100),
    IN    Aggregates VARCHAR(100))
BEGIN
	DECLARE End       INT         DEFAULT Locate('!', Aggregates);
    DECLARE Start     INT         DEFAULT 1;
    DECLARE Aggregate VARCHAR(13) DEFAULT '';
    DECLARE CastIndx  INT;
    DECLARE CastCL    VARCHAR(1000);
    
    WHILE End != -1 DO
        IF End = 0 THEN
            /*
             * This the final field, so extract to end of fields and set End to -1 to exit.
             */
			SET Aggregate = SubString(Aggregates, Start);
            SET End       = -1;
		ELSE       
			SET Aggregate = SubString(Aggregates, Start, End - Start);
            SET Start     = End + 1;            
            SET End       = Locate('!', Aggregates, Start);
        END IF;
        
        SET Aggregate = Trim(Aggregate);
        
        SET CastIndx = Locate(':', Aggregate);
        
        IF CastIndx = 0 THEN
			SET CastCl = NULL;
		ELSE
			SET CastCl = CONCAT('DECIMAL(', SUBSTRING(Aggregate, CastIndx + 1), ')');
            SET Aggregate = SUBSTRING(Aggregate, 1, CastIndx - 1);
        END IF;
        
        CALL AddSelectField(Fields, Field, CastCl, NULL, Aggregate);
	END WHILE;
END$$
DELIMITER ;

DROP PROCEDURE IF EXISTS AnalyseBP;

DELIMITER $$
/*
 * Period specifies the aggregation period and can be Year, Month, Week or Date.
 */
CREATE PROCEDURE AnalyseBP (Period VARCHAR(10), WhereAnd VARCHAR(1000))
sp: BEGIN
	DECLARE Fields    VARCHAR(10000); 
    DECLARE GroupBy   VARCHAR(1000); 
    DECLARE OrderBy   VARCHAR(1000) DEFAULT '';
    DECLARE NoOrderBy VARCHAR(1000) DEFAULT NULL;
    DECLARE WhereCl   VARCHAR(1000) DEFAULT "Orientation IS NULL";
    DECLARE Message   VARCHAR(1000) DEFAULT '';
    
    IF WhereAnd IS NOT NULL AND WhereAnd <> '' Then
		SET WhereCl = CONCAT(WhereCl, ' AND ', WhereAnd);
	END IF;
    
    CALL AddGroupField('Individual', GroupBy, Fields, OrderBy, NULL);
    
    CASE Period
		WHEN 'Year' THEN
			CALL AddGroupField('Year', GroupBy, Fields, OrderBy, 'DESC');
        WHEN 'Month' THEN
			CALL AddGroupField('Year',  GroupBy, Fields, OrderBy, 'DESC');
			CALL AddGroupField('Month', GroupBy, Fields, OrderBy, 'DESC');
        WHEN 'Week'  THEN
			CALL AddGroupField('Year', GroupBy, Fields, OrderBy, 'DESC');
			CALL AddGroupField('Week', GroupBy, Fields, OrderBy, 'DESC');
        WHEN 'Date'  THEN
			CALL AddGroupField('Date', GroupBy, Fields, OrderBy, 'DESC');
        ELSE
			SET Message = CONCAT('Period ', Period, ' is not valid');
            SELECT Message;
            LEAVE sp;
	END CASE;
    
	CALL AddGroupField('Side', GroupBy, Fields, NoOrderBy, NULL);
	CALL AddSelectField(Fields, 'Count(*)', NULL,    'Measures', NULL);
    CALL AddAggregateField(Fields, 'Systolic',  'Min!Avg:4,1!Max!Std:4,2');
    CALL AddAggregateField(Fields, 'Diastolic', 'Min!Avg:4,1!Max!Std:4,2');
    
    SET @Query = CONCAT(
		'SELECT \n\r', Fields, 
        '\n\rFROM BloodPressure.MeasureTry', 
        '\n\rWhere ', WhereCl, 
        '\n\rGroup By ', GroupBy, 
        '\n\rOrder By ', OrderBy);
        
    PREPARE STMT FROM @Query; 
    EXECUTE STMT; 
    DEALLOCATE PREPARE STMT;
END$$

DELIMITER ;

DROP PROCEDURE IF EXISTS TestSplit;

DELIMITER $$

CREATE PROCEDURE TestSplit(
	IN Fields VARCHAR(10000),
    IN Sep    VARCHAR(1))
BEGIN
	DECLARE End    INT           DEFAULT Locate(Sep, Fields);
    DECLARE Start  INT           DEFAULT 1;
    DECLARE Field  VARCHAR(1000) DEFAULT '';
    DECLARE Result VARCHAR(1000) DEFAULT NULL;
    
    WHILE End != -1 DO
        IF End = 0 THEN
            /*
             * This the final field, so extract to end of fields and set End to -1 to exit.
             */
			SET Field = SubString(Fields, Start);
            SET End   = -1;
		ELSE       
			SET Field = SubString(Fields, Start, End - Start);
            SET Start = End + 1;            
            SET End   = Locate(Sep, Fields, Start);
        END IF;
        
        SET Field = Trim(Field);
        /*
         * Process value. The following is for testing 
         */
		If Result IS NULL THEN
			SET Result = Field;
		ELSE
			SET Result = CONCAT(Result, '!', Field);
		END IF;
	END WHILE;
    
    SELECT Result;
END$$
DELIMITER ;


