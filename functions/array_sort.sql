CREATE OR REPLACE FUNCTION sort(anyarray) 
    RETURNS anyarray
    language sql
    set search_path = ''
AS $$
  SELECT array(SELECT * FROM unnest($1) ORDER BY 1); 
$$;
