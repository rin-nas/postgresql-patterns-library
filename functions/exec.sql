-- source: https://www.crunchydata.com/blog/dynamic-ddl-in-postgresql

/*
-- Problem:
ALTER SEQUENCE big_table_id_seq RESTART (SELECT max(id) + 1 FROM big_table);
ERROR:  syntax error at or near "(", at character 41
STATEMENT:  ALTER SEQUENCE big_table_id_seq RESTART (SELECT max(id) + 1 FROM big_table);

-- Solution 1 with psql:

-- use \gset to set a psql variable with the results of this query
SELECT max(id) + 1 as big_table_max from big_table \gset
-- substitute the variable in a new query
ALTER SEQUENCE big_table_id_seq RESTART :big_table_max ;

*/

-- Solution 2 without psql:

CREATE OR REPLACE FUNCTION exec(raw_query text) RETURNS text AS $$
BEGIN
  EXECUTE raw_query;
  RETURN raw_query;
END
$$
LANGUAGE plpgsql;

-- TEST
-- SELECT exec(format('ALTER SEQUENCE big_table_id_seq RESTART %s', (SELECT max(id) + 1 FROM big_table)));
