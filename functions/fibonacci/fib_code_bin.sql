create or replace function public.fib_code_bin(n int)
    returns bit
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select public.bin(
               public.bit_reverse(n) << 1 | 1, --add bit 1 to end
               bit_length(public.bin(n)) + 1
           )
$func$;

comment on function public.fib_code_bin(n int) is $$
    Converts Fibonacci integer type to universal code as bit type.
    https://en.wikipedia.org/wiki/Fibonacci_coding
    Example:
    dec => fib_code_bin
    1 => 11
    2 => 011
    3 => 0011
    4 => 1011
    5 => 00011
    6 => 10011
    7 => 01011
    8 => 000011
    9 => 100011
    ...
$$;

--TEST
select dec,
       fib_bin,
       bit_length(fib_bin) as fib_bin_length
from generate_series(1, 100) as dec
cross join lateral (select array(select t.n from public.fib_seq(47) as t(n) offset 2)) as f(seq) --1 2 3 5 8 13 21...
cross join public.fib_encode(dec, f.seq) as fib
cross join public.fib_code_bin(fib) as fib_bin;
