--simplest and faster
CREATE FUNCTION public.array_unique(anyarray)
    returns anyarray
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $$
    SELECT array_agg(DISTINCT x) --using DISTINCT implicitly sorts the array
    FROM unnest($1) t(x);
$$;

CREATE FUNCTION public.array_unique(
      anyarray, -- input array 
      boolean -- flag to drop nulls
) 
    RETURNS anyarray
    immutable
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
