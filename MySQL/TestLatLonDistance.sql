SET @distance = 1;
SET @lat      = 51.0574;
SET @lon      = -1.3428;

SET @latml    = 68.703;
SET @lonml    = (90 - @lat) * 3.1415927 / 180 * 69.172;

SET @latmx    = @lat + @distance / @latml;
SET @latmn    = @lat - @distance / @latml;

SET @lonmx    = @lon + @distance / @lonml;
SET @lonmn    = @lon - @distance / @lonml;

SELECT @lonml, @latmn, @latmx, @lonmn, @lonmx;

SELECT 
	*,
    accrm.DistanceBetween(@lat, @lon, Latitude, Longitude)
FROM accrm.postcodes 
WHERE Latitude  BETWEEN @latmn AND @latmx
AND   Longitude BETWEEN @lonmn AND @lonmx
AND   accrm.DistanceBetween(@lat, @lon, Latitude, Longitude) <= @distance
ORDER BY accrm.DistanceBetween(@lat, @lon, Latitude, Longitude) DESC;


SELECT 
	*,
    accrm.DistanceBetween(@lat, @lon, Latitude, Longitude)
FROM accrm.postcodes 
WHERE accrm.DistanceBetween(@lat, @lon, Latitude, Longitude) <= @distance
ORDER BY accrm.DistanceBetween(@lat, @lon, Latitude, Longitude) DESC;

SELECT accrm.MilesPer1DegreeLongitude(51.057);