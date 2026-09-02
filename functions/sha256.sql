-- The function needs the pgcrypto package

create or replace function public.sha256(bytea)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
return
    encode(digest($1, 'sha256'), 'hex');

comment on function public.sha256(bytea) IS 'Returns a SHA254 hash for the given string.';
