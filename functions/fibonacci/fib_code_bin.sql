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
       fib_code_bin(fib)
from generate_series(1, 500) as dec
cross join fib_encode(dec) as fib;
