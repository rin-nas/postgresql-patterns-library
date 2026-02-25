-- source: https://www.crunchydata.com/blog/dynamic-ddl-in-postgresql
CREATE OR REPLACE FUNCTION exec(raw_query text) RETURNS text AS $$
BEGIN
  EXECUTE raw_query;
  RETURN raw_query;
END
$$
LANGUAGE plpgsql;

-- TEST
-- SELECT exec(format('ALTER SEQUENCE big_table_id_seq RESTART %s', (SELECT max(id) + 1 FROM big_table)));
