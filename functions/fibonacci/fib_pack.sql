create or replace function public.fib_pack(a int[])
    returns bytea
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    select public.bit_to_bytea(
                public.bit_agg(
                    public.fib_code_bin(
                        public.fib_encode(u.dec, f.seq)
                    )
                )
           )
    from unnest(a) as u(dec),
         coalesce(array(select t.n from public.fib_seq(47) as t(n) offset 2)) as f(seq); --1 2 3 5 8 13 21...
$func$;

comment on function public.fib_pack(a int[]) is 'Packs integers (with values > 0) by Fibonacci encoding algorithm to bytea';

--TEST
do $$
    begin
        assert public.fib_pack('{1,2,3,4,5,6,7,8,9,10,11,12,13}') = '\xD9D8E6B0E34CBAC180';
        assert public.fib_pack('{13,12,11,10,9,8,7,6,5,4,3,2,1}') = '\x075969C61AE63B3780';
    end;
$$;
