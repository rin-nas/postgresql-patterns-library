-- The function needs the pgcrypto package

CREATE OR REPLACE FUNCTION public.sha256(bytea)
    returns text
    immutable
    returns null on null input
    parallel safe -- postgres 10 or later
    language sql
    set search_path = ''
AS $func$
    SELECT ENCODE(digest($1, 'sha256'), 'hex')
$func$;

COMMENT ON FUNCTION public.sha256(bytea) IS 'Returns a SHA254 hash for the given string.';
