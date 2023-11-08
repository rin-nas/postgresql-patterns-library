create or replace function public.mtf_encode(a int[])
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
            IF n < 1 THEN
                RETURN null;
            END IF;
            n_max := greatest(n_max, n);
        END LOOP;

        FOR i IN 1..n_max LOOP
            t[i] := i;
        END LOOP;

        FOREACH n IN ARRAY a LOOP
            i := array_position(t, n);
            r := array_append(r, i);
            t := t[i] || t[:i-1] || t[i+1:];
        END LOOP;

        RETURN r;
    end;
$func$;

comment on function public.mtf_encode(a int[]) is 'https://en.wikipedia.org/wiki/Move-to-front_transform';

-- TEST
do $$
    begin
        --negative
        assert public.mtf_encode('{-1, 0, 1}') is null;

        --positive
        assert(
            with t (a) as (
                select array(select ascii(t.c) from regexp_split_to_table('', '') as t(c) where t.c != '')
            )
            select public.mtf_encode(a) = '{}'::int[]
            from t
        );

        assert(
            with t (a) as (
                select array(select ascii(t.c) from regexp_split_to_table('inefficiencies', '') as t(c) where t.c != '')
            )
            select public.mtf_encode(a) = '{105,110,103,104,1,4,103,2,4,5,4,4,4,115}'::int[]
            from t
        );

        assert (
            with t (a) as (
                select array(select ascii(t.c) from regexp_split_to_table('неэффективность', '') as t(c) where t.c != '')
            )
            select public.mtf_encode(a) = '{1085,1078,1101,1093,1,3,1085,1092,1085,1081,8,1089,1092,6,1101}'::int[]
            from t
        );

        --https://doc.lagout.org/Others/Information%20Theory/Compression/Data%20Compression%20The%20Complete%20Reference%203rd%20Ed%20-%20David%20Salomon.pdf
        assert (
            with t (a) as (
                select array(select ascii(t.c) from regexp_split_to_table('abcdmnopabcdmnop', '') as t(c) where t.c != '')
            )
            select public.mtf_encode(a) = '{97,98,99,100,109,110,111,112,8,8,8,8,8,8,8,8}'
            from t
        );
    end
$$;
