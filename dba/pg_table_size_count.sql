WITH t AS (
    SELECT n.nspname || '.' || c.relname AS relation,
           pg_relation_size(c.oid) AS table_size,
           pg_total_relation_size(c.oid) - pg_relation_size(c.oid) - pg_indexes_size(c.oid) AS toast_size,
           pg_indexes_size(c.oid) AS indexes_size,
           pg_total_relation_size(c.oid) AS total_size,
           (select reltuples::bigint
            from pg_class
            where  oid = (n.nspname || '.' || c.relname)::regclass
           ) as rows_estimate_count
    FROM pg_class AS c
    JOIN pg_namespace AS n ON n.oid = c.relnamespace
    WHERE nspname NOT IN ('pg_catalog', 'information_schema')
      AND c.relkind not in ('i', 'S') -- without indexes and sequences
      AND nspname !~ '^pg_toast'
      --AND relname LIKE 'messenger__message_banners%'
)
    (SELECT relation,
            pg_size_pretty(table_size) as table_size_pretty,
            pg_size_pretty(total_size - table_size - indexes_size) as toast_size_pretty,
            pg_size_pretty(indexes_size) as indexes_size_pretty,
            pg_size_pretty(total_size) as total_size_pretty,
            coalesce(round(total_size * 100 / nullif(sum(total_size) over(), 0), 2), 0) as total_size_percent,
            regexp_replace(rows_estimate_count::text, '(?<=\d)(?<!\.[^.]*)(?=(\d\d\d)+(?!\d))', ',', 'g') as rows_estimate_count_pretty,
            coalesce(round(rows_estimate_count * 100 / nullif(sum(rows_estimate_count) over(), 0), 2), 0) as rows_estimate_count_percent
     FROM t
     ORDER BY total_size DESC
     --ORDER BY rows_estimate_count DESC
    )
UNION ALL
(SELECT 'TOTAL',
        pg_size_pretty(SUM(table_size)),
        pg_size_pretty(SUM(toast_size)),
        pg_size_pretty(SUM(indexes_size)),
        pg_size_pretty(SUM(total_size)),
        100,
        regexp_replace(SUM(rows_estimate_count)::text, '(?<=\d)(?<!\.[^.]*)(?=(\d\d\d)+(?!\d))', ',', 'g'),
        100
 FROM t);
