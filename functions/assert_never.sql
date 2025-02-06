-- https://hakibenita.com/future-proof-sql#assert-never-in-sql
-- https://docs.python.org/3.11/library/typing.html#typing.assert_never

-- DEPRECATED, use raise_exception() instead

CREATE OR REPLACE FUNCTION assert_never(v anyelement)
RETURNS anyelement
LANGUAGE plpgsql AS
$$
BEGIN
    RAISE EXCEPTION 'Unhandled value "%"', v;
END;
$$;
