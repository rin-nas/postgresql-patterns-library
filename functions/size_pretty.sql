create function public.size_pretty(bigint)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
return
    case when $1 = 0 then '0'
         else replace(pg_size_pretty($1), ' bytes', ' B')
    end;

comment on function public.size_pretty(bigint) is 'Formats the size to a human readable string';


create function public.size_pretty(numeric)
    returns text
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = 'pg_catalog, pg_temp' -- prevent SQL injection and privilege escalation attacks
return
    case when $1 = 0 then '0'
         else replace(pg_size_pretty($1), ' bytes', ' B')
    end;

comment on function public.size_pretty(numeric) is 'Formats the size to a human readable string';
