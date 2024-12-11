-- TODO
select regexp_replace(
    'select * from a inner join b where a.f = b.f order by a.id limit 10', 
    '\s+(FROM|CROSS|LEFT|RIGHT|INNER|OUTER|JOIN|WHERE|HAVING|ON|GROUP BY|ORDER BY|LIMIT|SELECT|UNION|INTERSECT|EXCEPT)(\s)',
    E'\n\\1\\2',
    'gi'
);
