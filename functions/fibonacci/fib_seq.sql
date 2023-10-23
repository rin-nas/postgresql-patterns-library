CREATE OR REPLACE FUNCTION public.fib_seq(total int)
    returns setof int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS
$func$
DECLARE
    a int := 0;
    b int := 1;

    i int := 2;
    min_total int := 3;
    max_total int := 47;
BEGIN
    --inspired by: https://stackoverflow.com/questions/75588188/generating-fibonacci-sequence-with-pl-pgsql-function

    IF total NOT BETWEEN min_total AND max_total THEN
        RAISE EXCEPTION 'First parameter betwen % and % expected, % given', min_total, max_total, total;
    END IF;

    RETURN NEXT a;
    RETURN NEXT b;
    LOOP
        i := i + 1;
        a := a + b;
        RETURN NEXT a;
        EXIT WHEN i = total;

        i := i + 1;
        b := b + a;
        RETURN NEXT b;
        EXIT WHEN i = total;
    END LOOP;
END;
$func$;

comment on function public.fib_seq(total int) is $$
    Generates Fibonacci sequence.
    Fibonacci numbers form a sequence such that each number is the sum of the two preceding numbers, starting from 0 and 1.
$$;

--TEST
do $$
    begin
        assert (
            select array(select fib from public.fib_seq(32) as t(fib))
                 = '{0,1,1,2,3,5,8,13,21,34,55,89,144,233,377,610,987,1597,2584,4181,6765,10946,17711,28657,46368,75025,121393,196418,317811,514229,832040,1346269}'
        );
    end;
$$;

/*
Fibonacci sequence numbers with recursive in PostgreSQL
with recursive r(a, b) as (
    select 0::int, 1::int
    union all
    select b, a + b
    from r
    where b < 1000
)
select a from r;
*/
