CREATE OR REPLACE FUNCTION public.negafibonacci_sequence(total int)
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

    RETURN NEXT 0;
    RETURN NEXT 1;
    LOOP
        i := i + 1;
        a := a - b;
        RETURN NEXT a;
        EXIT WHEN i = total;

        i := i + 1;
        b := b - a;
        RETURN NEXT b;
        EXIT WHEN i = total;
    END LOOP;
END;
$func$;

comment on function public.negafibonacci_sequence(total int) is $$
    Generates negative Fibonacci sequence.
$$;


--TEST
do $$
    begin
        assert (select count(*) = 32 and sum(v) = 832041 and max(v) = 1346269
                from public.negafibonacci_sequence(32) with ordinality as t(v, o)
               );
    end;
$$;

--select array(select public.negafibonacci_sequence(32));
