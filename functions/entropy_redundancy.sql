create or replace function public.entropy_redundancy(s text)
    returns numeric
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select log(2, char_length(entropy_redundancy.s)) - public.entropy(entropy_redundancy.s);
$func$;

comment on function public.entropy_redundancy(s text) is 'Returns text redundancy > 0';


create or replace function public.entropy_redundancy(data bytea)
    returns numeric
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select log(2, octet_length(entropy_redundancy.data)) - public.entropy(entropy_redundancy.data);
$func$;

comment on function public.entropy_redundancy(s text) is 'Returns data redundancy > 0. For compressed data the value tends to 0';


-- TEST
do $$
    begin
        assert round(public.entropy_redundancy('abracadabra'), 2) = 1.42;
        assert round(public.entropy_redundancy('абракадабра'), 2) = 1.42;
        assert round(public.entropy_redundancy('абракадабра'::bytea), 2) = 2.1;
        assert round(public.entropy_redundancy('\x11D481C8E032988E9763FD2780'::bytea), 2) = 0;
    end;
$$;
