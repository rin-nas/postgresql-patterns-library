create or replace function public.zigzag_decode(n int)
    returns int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select (n >> 1) # - (n & 1);
$func$;

comment on function public.zigzag_decode(n int) is $$
    Converts a zigzag-encoded unsigned integer to signed integer.
    Examples:
    9 => -5
    7 => -4
    5 => -3
    3 => -2
    1 => -1
    0 => 0
    2 => 1
    4 => 2
    6 => 3
    8 => 4
    10 => 5
$$;

--TEST
DO $$
    BEGIN
        assert (
            select (count(*), sum(i), sum(x)) = (11, 55, 0)
            from generate_series(0, 10) as i
            cross join public.zigzag_decode(i) as x
        );
    END
$$;
