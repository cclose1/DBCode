


SELECT
	LN1.TXNId,
	LN1.Line,
	LN1.Account,
	LN1.Amount,
	LN1.Currency,
	LN1.Type,
	LN2.Line,
	LN2.Account,
	LN2.Amount,
	LN2.Currency,
	LN2.Type
FROM MergeTransactionLines LN1
 JOIN MergeTransactionLines LN2
ON  LN1.TXNId = LN2.TXNId
AND  LN1.Line  = 1
--AND LN2.Line <> 1
ORDER BY LN1.TXNId