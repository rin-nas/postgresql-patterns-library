-- TODO
select trim(regexp_replace(
         'select * from a inner join b where a.f = b.f order by a.id limit 10', 
         '\s*\m(?<!\|)(FROM|NATURAL|(?:CROSS\s+|LEFT\s+|RIGHT\s+|INNER\s+)?(?:OUTER\s+)?JOIN|WHERE|HAVING|ON|USING|GROUP BY|ORDER BY|LIMIT|SELECT|UNION|INTERSECT|EXCEPT|CASE|WHEN|ELSE|END)(?!\|)\M',
         E'\n\\1',
         'gi'
       ), E'\n ') as query_pretty
