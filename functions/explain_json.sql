CREATE OR REPLACE FUNCTION public.explain_json(
    query TEXT,
    params TEXT[] DEFAULT ARRAY[]::text[]
) RETURNS SETOF JSON
    LANGUAGE plpgsql
    set search_path = ''
AS $$
BEGIN
    RETURN QUERY
    EXECUTE 'EXPLAIN ('
         || ARRAY_TO_STRING(ARRAY_APPEND(params, 'FORMAT JSON'), ',')
         || ')'
         || query;
END
$$;

--TEST
SELECT (public.explain_json('SELECT * FROM pg_class', ARRAY['ANALYSE'])->0->'Plan'->>'Total Cost')::numeric AS cost

--TODO добавить 3-й параметр в функцию: returns_null_on_error
--select  explain_json('select unknown_col from pg_class');
