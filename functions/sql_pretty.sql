-- TODO
select regexp_replace(
  'select * from a inner join b where a.f = b.f order by a.id limit 10', 
  '\s*\m(FROM|CROSS|LEFT|RIGHT|INNER|OUTER|JOIN|WHERE|HAVING|ON|GROUP BY|ORDER BY|LIMIT|SELECT|UNION|INTERSECT|EXCEPT|CASE|WHEN|ELSE|END)\M',
  E'\n\\1',
  'gi'
) as query_pretty
