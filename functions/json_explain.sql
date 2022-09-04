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
SELECT json_explain('SELECT * FROM pg_class', ARRAY['ANALYSE'])->0;
