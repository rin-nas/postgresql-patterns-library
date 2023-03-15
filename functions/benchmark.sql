-- PostgreSQL equivalent of MySQL's BENCHMARK() function

CREATE OR REPLACE FUNCTION benchmark(loop_count int, sql_expr text) returns interval
    volatile
    returns null on null input -- = strict
    parallel unsafe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS
$$
DECLARE
    sql text;
    started_at timestamptz;
BEGIN
    sql := concat('select (', sql_expr, ') is null from generate_series(1, $1)');
    started_at := clock_timestamp();
    EXECUTE sql USING loop_count;
    RETURN clock_timestamp() - started_at;
END
$$;

CREATE OR REPLACE FUNCTION benchmark(timeout interval, sql_expr text) returns int
    volatile
    returns null on null input -- = strict
    parallel unsafe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS
$$
DECLARE
    sql text;
    loop_count int;
BEGIN
    sql := concat('with recursive r (i, b) as (
                        select 1, (', sql_expr, ') is null
                        where clock_timestamp() < $1
                        union
                        select i + 1, (', sql_expr, ') is null
                        from r
                        where clock_timestamp() < $1
                   )
                   select max(i) from r');
    EXECUTE sql USING timeout + clock_timestamp() INTO loop_count;
    RETURN loop_count;
END
$$;

-- TESTS
do $$
    begin
        assert benchmark(1000, 'gen_random_uuid()') > '0'::interval;
        assert benchmark('10ms'::interval, 'gen_random_uuid()') > 0;
    end;
$$;

-- EXAMPLE 1: parse URL
select benchmark(100000, $$substring(format('https://www.domain%s.com/?aaa=1111&b[2]=3#test', (random()*1000)::int::text) from '^[^:]+://([^/]+)')$$);

-- EXAMPLE 2: generate UUID
SELECT benchmark(100000, $$uuid_in(overlay(overlay(md5(random()::text || ':' || clock_timestamp()::text) placing '4' from 13) placing to_hex(floor(random()*(11-8+1) + 8)::int)::text from 17)::cstring)$$);
SELECT benchmark(100000, $$md5(random()::text || clock_timestamp()::text)::uuid$$);

-- EXAMPLE 3: benchmark generate UUID
SELECT benchmark('1s'::interval, 'public.gen_random_uuid()'), public.gen_random_uuid() as guid
union all
SELECT benchmark('1s'::interval, 'public.uuid_generate_v7()'), public.uuid_generate_v7()
union all
SELECT benchmark('1s'::interval, 'public.uuid_generate_v8()'), public.uuid_generate_v8();
