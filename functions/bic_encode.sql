-- Binary Interpolative Code (BIC) algorithm invented by Moffat and Stuiver
with recursive r (s, m, n, l, h, w, b, d, t) as (
    select s,
           m, n,
           0, ss[len],
           w, b,
           0, null
    from coalesce(array[3, 4, 7, 13, 14, 15, 21, 25, 36, 38,54, 62]::int[]) as ss
    cross join array_length(ss, 1) as len
    cross join coalesce(len - 1) as n
    cross join ceil(n * 1.0 / 2) as m
    cross join coalesce(ss[:n]) as s
    cross join coalesce(s[m] - 0 - m + 1) as w
    cross join coalesce(log(2, s[n] - 0 - n + 1)) as b
    union all
    select * from (
        with rr as (
            select * from r --workaround [42P19] ERROR: recursive reference to query "r" must not appear more than once
        )
        select s.s,
               m.m, n.n,
               l.l, h.h,
               w.w, b.b,
               rr.d + 1, 'L'
        from rr
        cross join coalesce(case when rr.n = 2 then rr.s[2 : 2] else rr.s[1 : rr.m-1] end) as s(s)
        cross join array_length(s.s, 1) as n(n)
        cross join ceil(n.n * 1.0 / 2) as m(m)
        cross join coalesce(case when n.n = 1 then rr.s[rr.m] + 1 else rr.l end) as l(l)
        cross join coalesce(case when n.n = 1 then rr.h else rr.s[rr.m] - 1 end) as h(h)
        cross join coalesce(s.s[m.m] - l.l - m.m + 1) as w(w)
        cross join coalesce(h.h - l.l - n.n + 1) as g(g)
        cross join coalesce(case when g.g = 0 then 0 else log(2, g.g) end) as b(b)
        --cross join coalesce((h.h - l.l - n.n + 1)) as b(b)
        where rr.n > 1
          and (rr.n > 2 or rr.t = 'L')
          and rr.d < 1000 --infinite recursive protect on development
        union all -------------------------------------------------------------------------------------------
        select s.s,
               m.m, n.n,
               l.l, h.h,
               w.w, b.b,
               rr.d + 1, 'R'
        from rr
        cross join coalesce(case when rr.n = 2 then rr.s[rr.n : rr.n] else rr.s[rr.m + 1 : rr.n] end) as s(s)
        cross join array_length(s.s, 1) as n(n)
        cross join ceil(n.n * 1.0 / 2) as m(m)
        cross join coalesce(case when n.n = 0 then rr.l else rr.s[rr.m] + 1 end) as l(l)
        cross join coalesce(case when n.n = 0 then s.s[1] else rr.h end) as h(h)
        cross join coalesce(s.s[m.m] - l.l - m.m + 1) as w(w)
        cross join coalesce(h.h - l.l - n.n + 1) as g(g)
        cross join coalesce(case when g.g = 0 then 0 else log(2, g.g) end) as b(b)
        where rr.n > 1
          and (rr.n > 2 or rr.t = 'R')
          and d < 1000 --infinite recursive protect on development
   ) t
)
select *
from r
order by n desc, s;
