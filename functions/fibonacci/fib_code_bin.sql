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
               public.bit_reverse(n) << 1 | 1,
               bit_length(public.bin(n)) + 1
           )
$func$;

comment on function public.fib_code_bin(n int) is $$
    Converts Fibonacci integer type to universal code as bit type.
$$;
