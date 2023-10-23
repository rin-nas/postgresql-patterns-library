create or replace function public.fib_encode(n int, seq int[])
    returns int
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS $func$
DECLARE
    i int default cardinality(seq);
    r int default 0;
BEGIN
    while n > 0 loop
        if seq[i] is null then
            return null;
        end if;
        if seq[i] <= n then
            r := r | (1 << (i - 1));
            n := n - seq[i];
        end if;
        i := i - 1;
    end loop;
    return r;
END;
$func$;

comment on function public.fib_encode(n int, seq int[]) is 'Encode decimal number to fibonacci number';

--TEST
select dec, dec_bin,
       fib, fib_bin
from generate_series(0, 54) as dec
cross join lateral (select array(select t.n from public.fib_seq(47) as t(n) offset 2)) as f(seq) --1 2 3 5 8 13 21...
cross join fib_encode(dec,f.seq) as fib
cross join lpad(bin(dec)::text, 8, ' ') as dec_bin
cross join lpad(bin(fib)::text, 8, ' ') as fib_bin;
