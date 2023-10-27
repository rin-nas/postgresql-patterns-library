create or replace function public.fib_decode(n int, seq int[])
    returns int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS $func$
DECLARE
    r int default 0;
    i int default 1;
BEGIN
    while n > 0 loop
        if seq[i] is null then
            return null;
        end if;
        if (1 & n) = 1 then
            r := r + seq[i];
        end if;
        n := n >> 1;
        i := i + 1;
    end loop;
    return r;
END;
$func$;

comment on function public.fib_decode(n int, seq int[]) is $$
    Decode fibonacci number to decimal number.
    https://en.wikipedia.org/wiki/Fibonacci_coding
$$;

--TEST
do $$
    begin
        assert not exists(
            select dec, fib, dec2
            from generate_series(0, 54) as dec
            cross join lateral (select array(select t.n from public.fib_seq(47) as t(n) offset 2)) as f(seq) --1 2 3 5 8 13 21...
            cross join public.fib_encode(dec,f.seq) as fib
            cross join public.fib_decode(fib,f.seq) as dec2
            where dec is distinct from dec2
        );
    end;
$$;
