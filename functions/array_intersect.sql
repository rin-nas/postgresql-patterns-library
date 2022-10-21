create function array_intersect(anyarray, anyarray) returns anyarray
    immutable
    strict
    language sql
as
$$
  select array ( select unnest($1) intersect select unnest($2) order by 1 );
$$;
