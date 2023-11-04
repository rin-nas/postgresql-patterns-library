create or replace function public.fib_unpack(data bytea)
    returns int[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$
    with recursive r (b, bits) as (
        select substring(d.bits, 1, p.pos),
               substring(d.bits, p.pos + 2)
        from public.bit_from_bytea(fib_unpack.data) as d(bits),
             position(b'11' in d.bits) as p(pos)
        where p.pos > 0
        union all
        select substring(r.bits, 1, p.pos),
               substring(r.bits, p.pos + 2)
        from r,
             position(b'11' in r.bits) as p(pos)
        where p.pos > 0
    )
    select array(
        select public.fib_decode(
                   public.bit_reverse(b::int, bit_length(b)),
                   f.seq
               )
        from r,
             coalesce(array(select t.n from public.fib_seq(47) as t(n) offset 2)) as f(seq) --1 2 3 5 8 13 21...
    );
$func$;

comment on function public.fib_unpack(data bytea) is 'Unpacks bytea to integers by Fibonacci decoding algorithm';

--TEST
do $$
    begin
        assert public.fib_unpack(null) is null;
        assert public.fib_unpack('\x') = '{}';

        assert public.fib_unpack('\xD9D8E6B0E34CBAC180') = '{1,2,3,4,5,6,7,8,9,10,11,12,13}';
        assert public.fib_unpack('\x075969C61AE63B3780') = '{13,12,11,10,9,8,7,6,5,4,3,2,1}';
    end;
$$;
