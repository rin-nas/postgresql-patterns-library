-- PostgreSQL equivalent of MySQL's BENCHMARK() function

CREATE OR REPLACE FUNCTION benchmark(loop_count int,
                                     sql_expr text, -- SQL expression
                                     is_cache_plan boolean default true) returns interval
    immutable
    strict
    parallel safe -- Postgres 10 or later
    language plpgsql
AS
$$
BEGIN

    if is_cache_plan then
        EXECUTE 'select ($1) from generate_series(1, $2)' using sql_expr, loop_count;
    else
        FOR i IN 1..loop_count LOOP
            EXECUTE 'select ($1)' using sql_expr;
        END LOOP;
    end if;

    RETURN clock_timestamp() - now();
END
$$;

-- TESTS (parse URL)

select benchmark(
    500000,
    $$substring(format('https://www.domain%s.com/?aaa=1111&b[2]=3#test', (random()*1000)::int::text) from '^[^:]+://([^/]+)')$$,
    true);
-- 0 years 0 mons 0 days 0 hours 0 mins 0.300638 secs

select benchmark(
    500000,
    $$substring(format('https://www.domain%s.com/?aaa=1111&b[2]=3#test', (random()*1000)::int::text) from '^[^:]+://([^/]+)')$$,
    false);
-- 0 years 0 mons 0 days 0 hours 0 mins 6.735336 secs

-- TESTS (generate UUID)

SELECT benchmark(1000000, $$uuid_in(overlay(overlay(md5(random()::text || ':' || clock_timestamp()::text) placing '4' from 13) placing to_hex(floor(random()*(11-8+1) + 8)::int)::text from 17)::cstring)$$);
-- 0 years 0 mons 0 days 0 hours 0 mins 0.644648 secs

SELECT benchmark(1000000, $$md5(random()::text || clock_timestamp()::text)::uuid$$);
-- 0 years 0 mons 0 days 0 hours 0 mins 0.449026 secs

SELECT benchmark(1000000, $$gen_random_uuid()$$);
-- 0 years 0 mons 0 days 0 hours 0 mins 0.438084 secs
