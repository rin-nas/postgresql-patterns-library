create or replace function is_ogrn(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe
    language sql
    cost 2
as
$$
    --https://ru.wikipedia.org/wiki/Основной_государственный_регистрационный_номер
    --http://www.consultant.ru/cons/cgi/online.cgi?req=doc;base=LAW;n=179683
    select octet_length(str) = 13 and left((left(str, 12)::bigint % 11)::text, 1) = right(str, 1)
$$;

comment on function is_ogrn(text) is 'Проверяет, что переданная строка является ОГРН (основной государственный регистрационный номер)';

--TEST

DO $$
BEGIN
    --positive
    assert is_ogrn('0000000000000');
    assert is_ogrn('1000000000001');
    assert is_ogrn('1027812400868');

    --negative
    assert not is_ogrn('123456789012');
    assert not is_ogrn('12345678901234');
    assert not is_ogrn('0000000000001');
    assert not is_ogrn('1000000000000');
    assert not is_ogrn('1000000000002');
    assert not is_ogrn('1000000000003');
    assert not is_ogrn('1000000000004');
    assert not is_ogrn('1000000000005');
    assert not is_ogrn('1000000000006');
    assert not is_ogrn('1000000000007');
    assert not is_ogrn('1000000000008');
    assert not is_ogrn('1000000000008');

END $$;
