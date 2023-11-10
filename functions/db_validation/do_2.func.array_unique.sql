create or replace function db_validation.array_unique(anyarray)
    returns anyarray
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $$
    select array(
        select distinct t.x --using DISTINCT implicitly sorts the array
        from unnest($1) t(x)
    );
$$;

create or replace function db_validation.array_unique(
    anyarray, -- input array
    boolean -- flag to drop nulls
)
    returns anyarray
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $$
    select array(
        SELECT DISTINCT t.x --using DISTINCT implicitly sorts the array
        FROM unnest($1) t(x)
        WHERE NOT $2 OR t.x IS NOT NULL
    );
$$;

--TEST
do $$
    begin
        assert db_validation.array_unique('{}'::int[]) = '{}'::int[];
        assert db_validation.array_unique('{1,1,2,2,null,null}'::int[])  = '{null,1,2}';
        assert db_validation.array_unique('{x,x,y,y,null,null}'::text[]) = '{null,x,y}';

        assert db_validation.array_unique('{}'::int[], false) = '{}'::int[];
        assert db_validation.array_unique('{1,1,2,2,null,null}'::int[], false)  = '{null,1,2}';
        assert db_validation.array_unique('{x,x,y,y,null,null}'::text[], false) = '{null,x,y}';

        assert db_validation.array_unique('{}'::int[], true) = '{}'::int[];
        assert db_validation.array_unique('{1,1,2,2,null,null}'::int[], true)  = '{1,2}';
        assert db_validation.array_unique('{x,x,y,y,null,null}'::text[], true) = '{x,y}';
    end;
$$;
