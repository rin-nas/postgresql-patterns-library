create or replace function public.zigzag_encode(n int)
    returns int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select (n << 1) # (n >> 31);
$func$;

comment on function public.zigzag_encode(n int) is $$
    Zigzag encoding takes a signed integer and encodes it as an unsigned integer.
    It does so by counting up, starting at zero, alternating between representing a positive number and a negative number.
    Examples:
    -5 => 9
    -4 => 7
    -3 => 5
    -2 => 3
    -1 => 1
    0 => 0
    1 => 2
    2 => 4
    3 => 6
    4 => 8
    5 => 10
$$;

--TEST
DO $$
    BEGIN
        assert (
            select (count(*), sum(i), sum(x)) = (11, 0, 55)
            from generate_series(-5, 5) as i
            cross join public.zigzag_encode(i) as x
        );
    END
$$;

------------------------------------------------------------------------------------------------------------------------

create or replace function public.zigzag_encode(a int[], delta int default 0)
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
    begin
        while i < len loop
            i := i + 1;
            a[i] := public.zigzag_encode(a[i]) + delta;
        end loop;
        return a;
    end;
$func$;

--TEST
do $$
    begin
        assert public.zigzag_encode('{-2,-1,0,1,2}'::int[]) = '{3,1,0,2,4}'::int[];
    end;
$$;