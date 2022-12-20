create or replace function gc_dist(
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
