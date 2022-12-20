--simplest and faster
CREATE FUNCTION array_unique(anyarray)
    RETURNS anyarray
    stable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
AS $$
    SELECT array_agg(DISTINCT x) --using DISTINCT implicitly sorts the array
    FROM unnest($1) t(x);
$$;

CREATE FUNCTION array_unique(
      anyarray, -- input array 
      boolean -- flag to drop nulls
) 
    RETURNS anyarray
    stable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
AS $$
      SELECT array_agg(DISTINCT x) --using DISTINCT implicitly sorts the array
      FROM unnest($1) t(x) 
      --WHERE CASE WHEN $2 THEN x IS NOT NULL ELSE true END;
      WHERE NOT $2 OR x IS NOT NULL;
$$;
