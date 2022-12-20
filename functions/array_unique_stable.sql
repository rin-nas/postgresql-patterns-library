/*
Using DISTINCT implicitly sorts the array. 
If the relative order of the array elements needs to be preserved while removing duplicates, 
the function can be designed like the following: (should work from 9.4 onwards)
*/
CREATE OR REPLACE FUNCTION array_unique_stable(anyarray)
    RETURNS anyarray
    IMMUTABLE
    STRICT
    LANGUAGE sql
    set search_path = ''
AS $body$
SELECT
    array_agg(distinct_value ORDER BY first_index)
FROM 
    (SELECT
        value AS distinct_value, 
        min(index) AS first_index 
    FROM 
        unnest($1) WITH ORDINALITY AS input(value, index)
    GROUP BY
        value
    ) AS unique_input;
$body$;
