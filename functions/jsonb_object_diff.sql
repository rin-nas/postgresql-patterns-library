CREATE OR REPLACE FUNCTION public.jsonb_object_diff(l JSONB, r JSONB) RETURNS JSONB
    LANGUAGE sql
    set search_path = ''
AS $func$
    SELECT jsonb_object_agg(a.key, a.value)
    FROM (SELECT key, value FROM jsonb_each(l)) AS a(key,value)
    LEFT OUTER JOIN (SELECT key, value FROM jsonb_each(r)) b(key,value) ON a.key = b.key
    WHERE a.value != b.value OR b.key IS NULL;
$func$;

SELECT public.jsonb_object_diff('{"a":1,"b":2}'::JSONB, '{"a":1,"b":null}'::JSONB);

--Hstore style delete "-" operator for jsonb: https://github.com/glynastill/pg_jsonb_delete_op
