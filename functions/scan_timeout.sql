create or replace function scan_timeout(
    timeout interval,
    start_at timestamptz default statement_timestamp()
)
    returns boolean
    volatile
    called on null input --returns null on null input
    parallel restricted
    language plpgsql
    cost 2
as
$$
DECLARE
    elapsed constant interval default clock_timestamp() - start_at;
BEGIN

    if elapsed < timeout then
        return true;
    end if;

    raise exception
          using errcode = 'query_canceled',
          message = concat('Query cancelled by scan_timeout() function, timeout = ', timeout::text);
END
$$;

------------------------------------------------------------------------------------------------------------------------

create or replace function scan_timeout(
    timeout interval,
    id int,
    start_at timestamptz default statement_timestamp()
)
    returns boolean
    volatile
    called on null input --returns null on null input
    parallel restricted
    language plpgsql
    cost 2
as
$$
DECLARE
    elapsed constant interval default clock_timestamp() - start_at;
BEGIN

    if elapsed < timeout then
        return true;
    end if;

    raise exception
          using errcode = 'query_canceled',
          message = concat('Query cancelled by scan_timeout() function, timeout = ', timeout::text),
          hint = 'Detail error message has a JSON with id value, passed to scan_timeout() function',
          detail = jsonb_build_object('id', id);
END
$$;

comment on function scan_timeout(
    timeout interval,
    id int,
    start_at timestamptz
) is $$
Функция, которая позволяет остановить SELECT или DML запрос по таймауту.
В случае остановки запроса кидает исключение 'query_canceled'.
Чтобы это работало, в плане выполнения запроса "EXPLAIN (FORMAT JSON) ..." узел "Node Type" должен быть равен "Index Scan" или "Seq Scan".
Пример использования:
    SELECT t.*
    FROM t
    WHERE t.id > $1
      -- используем CASE для управления приоритетом выполнения условий сравнения
      AND CASE WHEN scan_timeout('5sec'::interval, t.id) THEN
              ... -- другие "тяжёлые" вычисления
          END
    ORDER BY t.id
$$;

------------------------------------------------------------------------------------------------------------------------
create or replace function scan_timeout(
    timeout interval,
    id bigint,
    start_at timestamptz default statement_timestamp()
)
    returns boolean
    volatile
    called on null input --returns null on null input
    parallel restricted
    language plpgsql
    cost 2
as
$$
DECLARE
    elapsed constant interval default clock_timestamp() - start_at;
BEGIN

    if elapsed < timeout then
        return true;
    end if;

    raise exception
          using errcode = 'query_canceled',
          message = concat('Query cancelled by scan_timeout() function, timeout = ', timeout::text),
          hint = 'Detail error message has a JSON with id value, passed to scan_timeout() function',
          detail = jsonb_build_object('id', id);
END
$$;

------------------------------------------------------------------------------------------------------------------------

create or replace function scan_timeout(
    timeout interval,
    id text,
    start_at timestamptz default statement_timestamp()
)
    returns boolean
    volatile
    called on null input --returns null on null input
    parallel restricted
    language plpgsql
    cost 2
as
$$
DECLARE
    elapsed constant interval default clock_timestamp() - start_at;
BEGIN

    if elapsed < timeout then
        return true;
    end if;

    raise exception
          using errcode = 'query_canceled',
          message = concat('Query cancelled by scan_timeout() function, timeout = ', timeout::text),
          hint = 'Detail error message has a JSON with id value, passed to scan_timeout() function',
          detail = jsonb_build_object('id', id);
END
$$;

------------------------------------------------------------------------------------------------------------------------

create or replace function scan_timeout(
    timeout interval,
    payload json,
    start_at timestamptz default statement_timestamp()
)
    returns boolean
    volatile
    called on null input --returns null on null input
    parallel restricted
    language plpgsql
    cost 2
as
$$
DECLARE
    elapsed constant interval default clock_timestamp() - start_at;
BEGIN

    if elapsed < timeout then
        return true;
    end if;

    raise exception
          using errcode = 'query_canceled',
          message = concat('Query cancelled by scan_timeout() function, timeout = ', timeout::text),
          hint = 'Detail error message has a JSON with payload value, passed to scan_timeout() function',
          detail = payload::text;
END
$$;

------------------------------------------------------------------------------------------------------------------------

create or replace function scan_timeout(
    timeout interval,
    payload jsonb,
    start_at timestamptz default statement_timestamp()
)
    returns boolean
    volatile
    called on null input --returns null on null input
    parallel restricted
    language plpgsql
    cost 2
as
$$
DECLARE
    elapsed constant interval default clock_timestamp() - start_at;
BEGIN

    if elapsed < timeout then
        return true;
    end if;

    raise exception
          using errcode = 'query_canceled',
          message = concat('Query cancelled by scan_timeout() function, timeout = ', timeout::text),
          hint = 'Detail error message has a JSON with payload value, passed to scan_timeout() function',
          detail = payload::text;
END
$$;

------------------------------------------------------------------------------------------------------------------------

--TEST

do $$
begin
    assert scan_timeout('1000ms'::interval);
    assert scan_timeout('1000ms'::interval, statement_timestamp());

    assert scan_timeout('1000ms'::interval, 1::int);
    assert scan_timeout('1000ms'::interval, 1::int, statement_timestamp());

    assert scan_timeout('1000ms'::interval, 1::bigint);
    assert scan_timeout('1000ms'::interval, 1::bigint, statement_timestamp());

    assert scan_timeout('1000ms'::interval, 'text');
    assert scan_timeout('1000ms'::interval, 'text', statement_timestamp());

    assert scan_timeout('1000ms'::interval, '{}'::json);
    assert scan_timeout('1000ms'::interval, '{}'::json, statement_timestamp());

    assert scan_timeout('1000ms'::interval, '[]'::jsonb);
    assert scan_timeout('1000ms'::interval, '[]'::jsonb, statement_timestamp());
end;
$$;
