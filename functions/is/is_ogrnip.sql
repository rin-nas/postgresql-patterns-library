create or replace function public.is_ogrnip(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
    cost 2
as
$$
    --https://ru.wikipedia.org/wiki/Основной_государственный_регистрационный_номер_индивидуального_предпринимателя
    --http://www.consultant.ru/cons/cgi/online.cgi?req=doc;base=LAW;n=179683
    select  octet_length(str) = 15
            and str !~ '\D'
            and right((left(str, 14)::bigint % 13)::text, 1) = right(str, 1)
$$;

comment on function public.is_ogrnip(text) is 'Проверяет, что переданная строка является ОГРНИП (основной государственный регистрационный номер индивидуального предпринимателя)';

--TEST

DO $$
BEGIN
    --positive
    assert public.is_ogrnip('000000000000000');
    assert public.is_ogrnip('100000000000001');
    assert public.is_ogrnip('307760324100018');

    --negative
    assert not public.is_ogrnip('12345678901234');
    assert not public.is_ogrnip('1234567890123456');
    assert not public.is_ogrnip('30776032410001a');
    assert not public.is_ogrnip('307760324100010');
    assert not public.is_ogrnip('307760324100011');
    assert not public.is_ogrnip('307760324100012');
    assert not public.is_ogrnip('307760324100013');
    assert not public.is_ogrnip('307760324100014');
    assert not public.is_ogrnip('307760324100015');
    assert not public.is_ogrnip('307760324100016');
    assert not public.is_ogrnip('307760324100017');
    assert not public.is_ogrnip('307760324100019');

END $$;
