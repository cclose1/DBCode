SELECT
	NC.Item   AS CItem,	
	ROW_NUMBER() OVER (PARTITION BY NRT.Timestamp ORDER BY NR.Item) AS ItemNo,
	NC.Source AS CSource,
	NC.Start,
	NC.[End],
	NC.Record,
	NR.Timestamp,
	NR.Item,
	NR.Source,
	NRT.Quantity,
	NRT.Timestamp AS TTimestamp	
FROM NutritionComposite NC
JOIN NutritionRecord    NR
ON NC.Record = NR.Timestamp
LEFT JOIN NutritionRecord NRT
ON  NR.Item      =  NRT.Item
AND NR.Source    =  NRT.Source
--AND NR.Quantity  =  NRT.Quantity
AND NR.Timestamp <> NRT.Timestamp
AND NRT.Timestamp BETWEEN NC.Start AND NC.[End]
WHERE NC.Item = 'Egg Mayo Baguette'
AND NRT.Item = 'Baguette'



--SELECT * INTO NutritionRecordCpy FROM NutritionRecord

EXEC SubstituteComposite 
		'Tuna Mayo Baguette', 
		'Nicola''s', 
		@matchQuantity = 'N',
		@update    = 'N',
		@timestamp = '2015-01-24 09:05:00'

SELECT COUNT(*) FROM NutritionRecord
SELECT COUNT(*) FROM NutritionRecordCpy

SELECT
	*
FROM NutritionRecordCpy
WHERE Source = 'Nicola''s'