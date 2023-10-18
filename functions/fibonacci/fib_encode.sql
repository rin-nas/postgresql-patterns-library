create or replace function public.fib_encode(n int)
    returns int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS $func$
DECLARE
    fibs int[] default (array(select public.fib_seq(47)))[3:]; -- 1 2 3 5 8 13 21 ...
    i int default cardinality(fibs);
    r int default 0;
BEGIN
    while n > 0 loop
        if fibs[i] <= n then
            r := r | (1 << (i - 1));
            n := n - fibs[i];
        end if;
        i := i - 1;
    end loop;
    return r;
END;
$func$;

comment on function public.fib_encode(n int) is 'Encode decimal number to fibonacci number';

--TEST
with recursive r (dec, fib) as (
    select 0 as i, public.fib_encode(0)
    union
    select dec + 1, public.fib_encode(dec + 1)
    from r
    where dec < 50
)
select dec, lpad(bin(dec), 8, ' ') as dec_bin,
       fib, lpad(bin(fib), 8, ' ') as fib_bin
from r;
