USE BloodPressure

PRINT 'Backup ' + BloodPressure.dbo.FormatDate(CURRENT_TIMESTAMP, 'DD-MMM-YY HH:MI:SS')
EXEC BloodPressure.dbo.TestMessage 'Testing' 
