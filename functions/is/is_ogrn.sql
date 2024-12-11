create or replace function public.is_ogrn(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
    cost 2
as
$$
    --https://ru.wikipedia.org/wiki/Основной_государственный_регистрационный_номер
    --http://www.consultant.ru/cons/cgi/online.cgi?req=doc;base=LAW;n=179683
    select  octet_length(str) = 13
            and str !~ '\D'
            and right((left(str, 12)::bigint % 11)::text, 1) = right(str, 1)
$$;

comment on function public.is_ogrn(text) is 'Проверяет, что переданная строка является ОГРН (основной государственный регистрационный номер)';

--TEST

DO $$
BEGIN
    --positive
    assert public.is_ogrn('0000000000000');
    assert public.is_ogrn('1000000000001');
    assert public.is_ogrn('1027812400868');

    --negative
    assert not public.is_ogrn('123456789012');
    assert not public.is_ogrn('12345678901234');
    assert not public.is_ogrn('102781240086a');
    assert not public.is_ogrn('0000000000001');
    assert not public.is_ogrn('1000000000000');
    assert not public.is_ogrn('1000000000002');
    assert not public.is_ogrn('1000000000003');
    assert not public.is_ogrn('1000000000004');
    assert not public.is_ogrn('1000000000005');
    assert not public.is_ogrn('1000000000006');
    assert not public.is_ogrn('1000000000007');
    assert not public.is_ogrn('1000000000008');
    assert not public.is_ogrn('1000000000008');

END $$;
