CREATE index LatIdx on accrm.postcodes(Latitude);
CREATE index LonIdx on accrm.postcodes(Longitude);

DROP Index LatIdx ON accrm.postcodes;
DROP Index LonIdx ON accrm.postcodes;