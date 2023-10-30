-- Binary Interpolative Code (BIC) algorithm invented by Moffat and Stuiver
-- https://github.com/jermp/interpolative_coding
-- http://pages.di.unipi.it/pibiri/papers/BIC.pdf
-- https://papers-gamma.link/static/memory/pdfs/204-Pibiri_Techniques_for_Inverted_Index_Compression_2020.pdf
create or replace function public.bic_encode(s int[], lo int, hi int, t char, d int)
    returns table (
        xx int,
        ss int[],
        mm int,
        nn int,
        ll int,
        hh int,
        ww int,
        rr int,
        bb int,
        dd int,
        tt char
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
    msb int;
    b int not null default 0;
begin
    if n > 0
       and hi - lo + 1 != n --run (sequence of consecutive values)
       and lo <= hi
    then
        x := s[m];
        w := x - lo - (m - 1);
        r := hi - lo - n + 1;
        msb := r;
        while msb > 0 loop
            msb := msb >> 1;
            b := b + 1;
        end loop;
        --raise notice 'x=%, s=%, m=%, n=%, lo=%, hi=%, w=%, b=%, d=%, t=%', x, s, m, n, lo, hi, w, b, d, t; --debug
        return query select x, s, m, n, lo, hi, w, r, b, d, t;
        return query select * from public.bic_encode(s[: m - 1], lo, x - 1, 'L', d + 1);
        return query select * from public.bic_encode(S[m + 1 :], x + 1, hi, 'R', d + 1);
    end if;
end
$$;

select *
from public.bic_encode('{3, 4, 7, 13, 14, 15, 21, 25, 36, 38, 54}', 0, 62, '*', 0)
order by dd, xx;
