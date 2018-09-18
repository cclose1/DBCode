USE BloodPressure;
SOURCE /tmp/sqlscripts/CreateBPTables.sql;
SOURCE /tmp/sqlscripts/CreateNutritionTables.sql;
SOURCE /tmp/sqlscripts/NutritionSps.sql;

# Create views
\! echo CreateNutritionViews.sql

SOURCE /tmp/sqlscripts/CreateNutritionViews.sql;

CREATE DATABASE Expenditure /*!40100 DEFAULT CHARACTER SET utf8 */;
USE Expenditure;
\! echo CreateExpenditureTables.sql
SOURCE /tmp/sqlscripts/CreateExpenditureTables.sql;
\! echo CreateBank.sql
SOURCE /tmp/sqlscripts/CreateBank.sql;
\! echo CreatePaymentSource.sql
SOURCE /tmp/sqlscripts/CreatePaymentSource.sql;
\! echo CreateUser.sql
SOURCE /tmp/sqlscripts/CreateUser.sql;
\! echo CreateSession.sql
SOURCE /tmp/sqlscripts/CreateSession.sql;

# Create views

\! echo CreateExpenseSummary.sql

SOURCE /tmp/sqlscripts/CreateExpenseSummary.sql;

\! echo CreateListValues.sql

SOURCE /tmp/sqlscripts/CreateListValues.sql;


GRANT INSERT, SELECT, UPDATE, DELETE ON BloodPressure.* TO 'appuser'@'%';
GRANT EXECUTE, INSERT, SELECT, UPDATE, DELETE ON Expenditure.*   TO 'appuser'@'%';
