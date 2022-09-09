create or replace function is_bank_account(
    rs text, --расчётный счёт
    bik text default null --если передан, то дополнительно в р/с происходит проверка контрольного числа по БИК
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

    --https://ru.wikipedia.org/wiki/Расчётный_счёт
    if octet_length(rs) != 20 or rs ~ '\D' then
        return false;
    elsif bik is null then
        return true;
    elsif not is_bik(bik) then
        return false;
    end if;

    --https://ru.wikipedia.org/wiki/Контрольное_число#Расчет_контрольного_числа
    --http://www.consultant.ru/document/cons_doc_LAW_16053/08c1d0eacf880db80ef56f68c3469e2ea24502d7/
    digits := string_to_array(right(bik, 3) || rs, null)::int[];

    while coefficients[i] is not null
    loop
        checksum := checksum + coefficients[i] * (digits[i] % 10);
        i := i + 1;
    end loop;

    return checksum % 10 = 0;

end;
$func$;

comment on function is_bank_account(rs text, bik text) is 'Проверяет, что переданная строка является расчётным счётом';

--TEST
DO $$
BEGIN
    --positive
    assert is_bank_account('12345678901234567890');
    assert is_bank_account('40817810099910004312');
    assert is_bank_account('00000000000000000000', '000000000');
    assert is_bank_account('40702810900000002851', '044030827');

    --negative
    assert not is_bank_account('*2345678901234567890');
    assert not is_bank_account('1234567890123456789');
    assert not is_bank_account('123456789012345678901');
    assert not is_bank_account('00702810900000002851', '044030827');
    assert not is_bank_account('10702810900000002851', '044030827');
    assert not is_bank_account('20702810900000002851', '044030827');
    assert not is_bank_account('30702810900000002851', '044030827');
    assert not is_bank_account('50702810900000002851', '044030827');
    assert not is_bank_account('60702810900000002851', '044030827');
    assert not is_bank_account('70702810900000002851', '044030827');
    assert not is_bank_account('80702810900000002851', '044030827');
    assert not is_bank_account('90702810900000002851', '044030827');
END $$;
