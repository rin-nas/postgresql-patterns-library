-- PostgreSQL < 13
CREATE AGGREGATE public.array_cat_agg(anyarray) (
    SFUNC     = array_cat
   ,STYPE     = anyarray
   ,INITCOND  = '{}'
);

-- PostgreSQL 13+
CREATE AGGREGATE public.array_cat_agg(anycompatiblearray) (
    SFUNC     = array_cat
   ,STYPE     = anycompatiblearray
   ,INITCOND  = '{}'
);

--TEST1
SELECT id,  public.array_cat_agg(words::text[])
FROM (VALUES
             ('1', '{"foo","bar","zap","bing"}'),
             ('2', '{"foo"}'),
             ('1', '{"bar","zap"}'),
             ('2', '{"bing"}'),
             ('1', '{"bing"}'),
             ('2', '{"foo","bar"}')) AS t(id, words)
GROUP BY id;

--TEST2 -- без функции array_cat_agg() можно обойтись, если немного переписать запрос!
SELECT id, array_agg(u.w) as words
FROM (VALUES
             ('1', '{"foo","bar","zap","bing"}'),
             ('2', '{"foo"}'),
             ('1', '{"bar","zap"}'),
             ('2', '{"bing"}'),
             ('1', '{"bing"}'),
             ('2', '{"foo","bar"}')) AS t(id, words),
unnest(words::text[]) as u(w)
GROUP BY id;
