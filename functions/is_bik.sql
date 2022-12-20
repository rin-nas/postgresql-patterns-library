create or replace function is_bik(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
    cost 5
as
$$
select
    octet_length(str) = 9
    and regexp_match(
        str,
        --https://ru.wikipedia.org/wiki/Банковский_идентификационный_код
        --https://www.consultant.ru/document/cons_doc_LAW_367694/fa4fb7b68518112d6b37e77c1b0bb56b6cca42eb/
        $regexp$
          ^
           [012]
           \d{8}
          $
        $regexp$, 'x') is not null
$$;

comment on function is_bik(text) is 'Проверяет, что переданная строка является БИК (Банковский Идентификационный Код)';

--TEST

DO $$
BEGIN
    --positive
    assert is_bik('000000000');
    assert is_bik('123456789');

    --negative
    assert not is_bik('987654321');
    assert not is_bik('123');
    assert not is_bik('1234567890');

END $$;
