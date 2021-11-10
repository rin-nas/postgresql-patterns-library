create or replace function is_macaddr(str text)
    returns boolean
    stable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
as
$$
    select regexp_match(
        str,
        --https://postgrespro.ru/docs/postgresql/12/datatype-net-types#DATATYPE-MACADDR
        $regexp$
          ^
           [\da-fA-F]{2}
           ([:\-])
           (?:[\da-fA-F]{2}\1){4}
           (?:(?:[\da-fA-F]{2}\1){2})?
           [\da-fA-F]{2}
          $
        $regexp$, 'x') is not null
$$;

comment on function is_macaddr(text) is 'Проверяет, что переданная строка является MAC адресом устройства';

--TEST

DO $$
BEGIN
    --positive
    assert is_macaddr('08:00:2b:01:02:03');
    assert is_macaddr('08-00-2b-01-02-03');
    assert is_macaddr('08:00:2b:01:02:03:04:05');
    assert is_macaddr('08-00-2b-01-02-03-04-05');

    --negative
    assert not is_macaddr('08.00.2b.01.02.03');
END $$;
