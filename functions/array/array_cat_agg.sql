CREATE AGGREGATE public.array_cat_agg(anyarray) (
    SFUNC     = array_cat
   ,STYPE     = anyarray
   ,INITCOND  = '{}'
);

--TEST
SELECT id,  public.array_cat_agg(words::text[])
FROM (VALUES
             ('1', '{"foo","bar","zap","bing"}'),
             ('2', '{"foo"}'),
             ('1', '{"bar","zap"}'),
             ('2', '{"bing"}'),
             ('1', '{"bing"}'),
             ('2', '{"foo","bar"}')) AS t(id, words)
GROUP BY id;
