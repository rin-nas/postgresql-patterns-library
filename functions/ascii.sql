create or replace function public.ascii(a text[])
    returns int[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
as $func$
    declare
        len int := cardinality(a);
        i int := 0;
        r int[] := '{}';
    begin
        while i < len loop
            i := i + 1;
            r[i] := ascii(a[i]);
        end loop;
        return r;
    end;
$func$;


--TEST
do $$
    begin
        assert public.ascii('{м,о,с,к,в,а}'::text[]) = '{1084,1086,1089,1082,1074,1072}'::int[];
    end;
$$;

