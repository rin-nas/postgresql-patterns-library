CREATE FUNCTION diff_tables(t1 regclass, t2 regclass) 
  returns TABLE("+/-" text, line text)
AS $func$
BEGIN
  RETURN QUERY EXECUTE format($$
   SELECT '+', d1.*::text FROM (
    SELECT * FROM %s
     EXCEPT
    SELECT * FROM %s) AS d1
   UNION ALL
   SELECT '-', d2.*::text FROM (
    SELECT * FROM %s
     EXCEPT
    SELECT * FROM %s) AS d2
   $$, t2, t1, t1, t2);
END
$func$ language plpgsql;

-- Source: https://github.com/dverite/postgresql-functions/blob/master/diff/diff-tables.sql

comment on function $$
  Takes two table names (through the regclass type), 
  and returns a set of diff-like results with the rows that differ. 
  It does not require a primary key on tables to compare.
$$;

-- TODO returns TABLE("+/-" text, line jsonb)
