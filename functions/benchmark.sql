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
    sql := concat('select (', sql_expr, ') from generate_series(1, $1)');
    started_at := clock_timestamp();
    EXECUTE sql USING loop_count;
    RETURN clock_timestamp() - started_at;
END
$$;

-- TESTS (parse URL)

select benchmark(100000, $$substring(format('https://www.domain%s.com/?aaa=1111&b[2]=3#test', (random()*1000)::int::text) from '^[^:]+://([^/]+)')$$);

-- TESTS (generate UUID)

SELECT benchmark(100000, $$uuid_in(overlay(overlay(md5(random()::text || ':' || clock_timestamp()::text) placing '4' from 13) placing to_hex(floor(random()*(11-8+1) + 8)::int)::text from 17)::cstring)$$);

SELECT benchmark(100000, $$md5(random()::text || clock_timestamp()::text)::uuid$$);

SELECT benchmark(100000, $$gen_random_uuid()$$);
