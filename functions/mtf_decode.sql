create or replace function public.mtf_decode(a int[])
    returns int[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
as $func$
    declare
        i int; --array index
        n int; --array element
        t int[] := '{}'; --table
        r int[] := '{}'; --return
        n_max int := -1;
    begin
        FOREACH n IN ARRAY a LOOP
            n_max := greatest(n_max, n);
        END LOOP;

        FOR i IN 1..n_max LOOP
            t[i] := i;
        END LOOP;

        FOREACH i IN ARRAY a LOOP
            n := t[i];
            r := array_append(r, n);
            t := t[i] || t[:i-1] || t[i+1:];
        END LOOP;

        return r;
    end;
$func$;

comment on function public.mtf_decode(a int[]) is 'https://en.wikipedia.org/wiki/Move-to-front_transform';

-- TEST
do $$
    begin
        assert(
            with t as (
                select unnest(public.mtf_decode('{}'::int[])) as code
            )
            select array_to_string(array(select chr(code) from t), '') = ''
        );

        assert(
            with t as (
                select unnest(public.mtf_decode('{105,110,103,104,1,4,103,2,4,5,4,4,4,115}'::int[])) as code
            )
            select array_to_string(array(select chr(code) from t), '') = 'inefficiencies'
        );

        assert (
            with t as (
                select unnest(public.mtf_decode('{1085,1078,1101,1093,1,3,1085,1092,1085,1081,8,1089,1092,6,1101}'::int[])) as code
            )
            select array_to_string(array(select chr(code) from t), '') = 'неэффективность'
        );
    end
$$;

