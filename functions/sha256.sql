-- The function needs the pgcrypto package

CREATE OR REPLACE FUNCTION sha256(bytea)
RETURNS text
STRICT
IMMUTABLE
LANGUAGE SQL
AS $func$
    SELECT ENCODE(digest($1, 'sha256'), 'hex')
$func$;

COMMENT ON FUNCTION sha256(bytea) IS 'Returns a SHA254 hash for the given string.';
