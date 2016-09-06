USE Expenditure
GO

IF EXISTS (SELECT '1' FROM sysobjects WHERE name = 'Summary' AND type ='p')
BEGIN
	DROP Procedure dbo.Summary
END
GO
CREATE PROCEDURE Summary(@adjustDay AS INT, @adjustAmount AS DECIMAL(10, 2))
AS
BEGIN
/*
 * Deleted original Summary by accident. Think the following is equivalent.
 * The original was also rewritten for MySQL. So could reconstruct from that. However, the
 * summary is not that vital.
 */
SELECT TOP 1
	AdHocDailyRate AS DailyRate,
	Essential,
	Discretionary,
	MonthSpend,
	YearTotal      AS YearEstimate,
	Target,
	UnderSpend
FROM Expenditure.dbo.Analyse(@adjustDay, @adjustDay)
ORDER BY Year DESC, Month DESC
END