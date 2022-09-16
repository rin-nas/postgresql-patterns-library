create or replace function is_correspondent_account(
    ks text, --к/с
    bik text default null --если передан, то дополнительно в к/с происходит проверка контрольного числа по БИК
)
    returns boolean
    immutable
    --returns null on null input
    parallel safe
    language plpgsql
    cost 7
as
$func$
declare
    digits int[];
    checksum int not null default 0;
    coefficients constant int[] not null default array[7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1, 3, 7, 1];
    i int default 1;
begin

    --https://ru.wikipedia.org/wiki/Корреспондентский_счёт
    if octet_length(ks) != 20 or ks !~ '^301\d+$' then
        return false;
    elsif bik is null then
        return true;
    elsif not is_bik(bik) then
        return false;
    end if;

    --http://www.consultant.ru/document/cons_doc_LAW_16053/08c1d0eacf880db80ef56f68c3469e2ea24502d7/
    digits := string_to_array('0' || substring(bik, 5, 2) || ks, null)::int[];

    while coefficients[i] is not null
    loop
        checksum := checksum + coefficients[i] * (digits[i] % 10);
        i := i + 1;
    end loop;

    return checksum % 10 = 0;

end;
$func$;

comment on function is_correspondent_account(ks text, bik text) is 'Проверяет, что переданная строка является корреспондентским счётом';

--TEST
DO $$
BEGIN
    --positive
    assert is_correspondent_account('30101810200000000827', '044030827');
    assert is_correspondent_account('30101810400000000225', '044525225');

    --negative
    assert not is_correspondent_account('3010181020000000082');
    assert not is_correspondent_account('301018102000000008270');
    assert not is_correspondent_account('3014567890123456789*');
    assert not is_correspondent_account('12345678901234567890');
    assert not is_correspondent_account('40817810099910004312');
    assert not is_correspondent_account('30101810300000000827', '044030827');
    assert not is_correspondent_account('30101810500000000225', '044525225');

END $$;
