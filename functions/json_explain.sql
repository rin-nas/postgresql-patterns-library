CREATE OR REPLACE FUNCTION json_explain(
    query TEXT,
    params TEXT[] DEFAULT ARRAY[]::text[]
) RETURNS SETOF JSON AS $$
BEGIN
    RETURN QUERY
    EXECUTE 'EXPLAIN ('
         || ARRAY_TO_STRING(ARRAY_APPEND(params, 'FORMAT JSON'), ',')
         || ')'
         || query;
END
$$ LANGUAGE plpgsql;

--TEST
SELECT (json_explain('SELECT * FROM pg_class', ARRAY['ANALYSE'])->0->'Plan'->>'Total Cost')::numeric as cost

--TODO добавить 3-й параметр в функцию: returns_null_on_error
--select json_explain('select unknown_col from pg_class');
