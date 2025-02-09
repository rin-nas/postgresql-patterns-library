create or replace function public.bic_encode_to_table(s int[], lo int, hi int, t char, d int)
    returns table (
        xx int, --list middle element value
        ss int[], --list
        mm int, --list middle element index
        nn int, --list cardinality
        ll int, --lo
        hh int, --hi
        ww int,
        rr int,
        dd int, --depth
        tt char --type: * - root, L - left, R -right
    )
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
as $$
declare
    n int not null default cardinality(s);
    m int not null default n / 2 + 1;
    x int;
    w int;
    r int;
begin
    if n <= 0
       or hi - lo + 1 = n --run (sequence of consecutive values)
       or lo > hi
    then
        return;
    end if;
    x := s[m];
    w := x - lo - (m - 1);
    r := hi - lo - n + 1;
    --raise notice 'x=%, s=%, m=%, n=%, lo=%, hi=%, w=%, b=%, d=%, t=%', x, s, m, n, lo, hi, w, b, d, t; --debug
    return query select x, s, m, n, lo, hi, w, r, d, t;
    return query select * from public.bic_encode_to_table(s[: m - 1], lo, x - 1, 'L', d + 1);
    return query select * from public.bic_encode_to_table(S[m + 1 :], x + 1, hi, 'R', d + 1);
end
$$;

create or replace function public.bic_encode(a int[])
    returns bytea
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$

    with t as (
        select bic_encode.a[ : c.c - 1] as s,
               bic_encode.a[c.c] as hi
        from cardinality(bic_encode.a) as c(c)
    )
    --select * from t; --debug
    , b as (
        select public.bit_agg(
                   public.bin(
                       e.ww,
                       bit_length(public.bin(e.rr))
                   )
               ) as bits
        from t,
             public.bic_encode_to_table(t.s, 0, t.hi, '*', 0) as e
        --order by dd, xx
    )
    --select * from b; --debug
    select public.bit_to_bytea(
                public.fib_code_bin(public.fib_encode(t.hi, f.seq))
                || b.bits
           )
    from b,
         t,
         coalesce(array(select t.n from public.fib_seq(47) as t(n) offset 2)) as f(seq); --1 2 3 5 8 13 21...
    ;
$func$;

comment on function public.bic_encode(a int[]) is $$
    Binary Interpolative Code (BIC) algorithm invented by Moffat and Stuiver
    http://pages.di.unipi.it/pibiri/papers/BIC.pdf
    https://papers-gamma.link/static/memory/pdfs/204-Pibiri_Techniques_for_Inverted_Index_Compression_2020.pdf
    https://github.com/jermp/interpolative_coding
$$;

--TEST
select public.bic_encode('{3,4,7,13,14,15,21,25,36,38,54,62}'::int[]);

--NOTE
--public.bic_encode() is great, but difficult, so try this:
select public.fib_pack(public.delta_encode('{3,4,7,13,14,15,21,25,36,38,54,62}'::int[]));

