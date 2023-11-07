create or replace function public.gc_dist(
    lat1 double precision, lon1 double precision,
    lat2 double precision, lon2 double precision
) returns double precision
    language plpgsql
    set search_path = ''
AS $$
    -- https://en.wikipedia.org/wiki/Haversine_formula
    -- http://www.movable-type.co.uk/scripts/latlong.html
    DECLARE R INT = 6371; -- km, https://en.wikipedia.org/wiki/Earth_radius
    DECLARE dLat double precision = (lat2-lat1)*PI()/180;
    DECLARE dLon double precision = (lon2-lon1)*PI()/180;
    DECLARE a double precision = sin(dLat/2) * sin(dLat/2) +
                                 cos(lat1*PI()/180) * cos(lat2*PI()/180) *
                                 sin(dLon/2) * sin(dLon/2);
    DECLARE c double precision = 2 * asin(sqrt(a));
BEGIN
    RETURN R * c;
EXCEPTION
-- если координаты совпадают, то получим исключение, а падать нельзя
WHEN numeric_value_out_of_range
    THEN RETURN 0;
END;
$$;


--TEST
with t as (
    SELECT 37.61556 AS msk_x, 55.75222 AS msk_y, -- координаты центра Москвы
           30.26417 AS spb_x, 59.89444 AS spb_y, -- координаты центра Санкт-Петербурга
           1.609344 AS mile_to_kilometre_ratio
)
select (point(msk_x, msk_y) <@> point(spb_x, spb_y)) * mile_to_kilometre_ratio AS dist1_km,
       public.gc_dist(msk_y, msk_x, spb_y, spb_x) AS dist2_km
from t;
