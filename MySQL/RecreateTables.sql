USE BloodPressure;


SELECT 'CreateBPTables.sql' AS '';

SOURCE C:/MySQLScripts/CreateBPTables.sql;

SELECT 'CreateNutritionTables.sql' AS '';

SOURCE C:/MySQLScripts/CreateNutritionTables.sql;

SELECT 'CreateNutritionViewsPRIMARY.sql' AS '';

SOURCE C:/MySQLScripts/CreateNutritionViews.sql;

USE Expenditure;

SELECT 'CreateExpenditureTables.sql' AS '';
SOURCE C:/MySQLScripts/CreateExpenditureTables.sql;

SELECT 'CreatePaymentSource.sql' AS '';
SOURCE C:/MySQLScripts/CreatePaymentSource.sql;

SELECT 'CreateUser.sql' AS '';
SOURCE C:/MySQLScripts/CreateUser.sql;

SELECT 'CreateSession.sql' AS '';
SOURCE C:/MySQLScripts/CreateSession.sql;

# Create views

SELECT 'CreateExpenseSummary.sql' AS '';

SOURCE C:/MySQLScripts/CreateExpenseSummary.sql;

SELECT 'CreateListValues.sql' AS '';

SOURCE C:/MySQLScripts/CreateListValues.sql;
