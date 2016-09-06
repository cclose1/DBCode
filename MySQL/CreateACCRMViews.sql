DROP VIEW IF EXISTS ProviderData;

CREATE VIEW ProviderData
AS
SELECT 
	PR.Id,
	PR.Start,
	PR.Name,
	PR.Comment  AS ProviderComment,
	SV.Name     AS Service,
	SVS.Comment AS ServiceCommment,
	CTS.Main,
	CTS.Comment AS ContactComment,
	CTY.Name    AS ContactType,
	CT.Role,
	CT.Name     AS ContactName,
	CT.Target,
	CV.PostCode,
	CV.Distance,
	CV.Comment  AS CoverageComment
FROM Provider PR
LEFT JOIN Services SVS
ON  PR.Id    = SVS.ProviderId
AND PR.Start BETWEEN SVS.Start AND SVS.End
JOIN Service SV
ON  SV.Id = SVS.ServiceId
LEFT JOIN contacts CTS
ON  PR.Id    = CTS.ProviderId
AND PR.Start BETWEEN CTS.Start AND CTS.End
JOIN Contact CT
ON  CTS.ContactId = CT.Id
AND CTS.Start     BETWEEN CT.Start AND CT.End
JOIN ContactType CTY
ON CT.Type = CTY.Id
LEFT JOIN Coverage CV
ON  PR.Id    = CV.ProviderId
AND PR.Start BETWEEN CV.Start AND CV.End