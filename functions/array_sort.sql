CREATE OR REPLACE FUNCTION sort(anyarray) 
RETURNS anyarray AS $$
  SELECT array(SELECT * FROM unnest($1) ORDER BY 1); 
$$ language sql;
