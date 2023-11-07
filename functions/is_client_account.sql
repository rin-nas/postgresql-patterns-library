create or replace function public.is_client_account(
    rs text, --расчётный счёт
    bik text default null --если передан, то дополнительно в р/с происходит проверка контрольного числа по БИК
)
    returns boolean
    immutable
    --returns null on null input
    parallel safe
    language plpgsql
    set search_path = ''
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
    --https://cbr.ru/na/385-p/ Положение Банка России «О правилах ведения бухгалтерского учета в кредитных организациях, расположенных на территории Российской Федерации» № 385-П от 16.07.2012
    if rs is null then
        return null;
    elsif octet_length(rs) != 20
        or rs ~ '\D'
        or rs ~ '^([1-9])\1+$'
    then
        return false;
    elsif bik is null then
        return true;
    elsif not public.is_bik(bik) then
        return false;
    end if;

    --https://ru.wikipedia.org/wiki/Контрольное_число#Расчет_контрольного_числа
    --http://www.consultant.ru/document/cons_doc_LAW_16053/08c1d0eacf880db80ef56f68c3469e2ea24502d7/
    --https://qna.habr.com/q/734667 Если расчетный счет открыт в РКЦ (7 и 8 знак номера БИКа это нули), то проверка проводится по алгоритму ключевания коррсчёта
    digits := case when substring(bik, 7, 2) != '00'
                   then string_to_array(right(bik, 3) || rs, null)::int[]
                   else string_to_array('0' || substring(bik, 5, 2) || rs, null)::int[]
              end;

    while coefficients[i] is not null
    loop
        checksum := checksum + coefficients[i] * (digits[i] % 10);
        i := i + 1;
    end loop;

    return checksum % 10 = 0;

end;
$func$;

comment on function public.is_client_account(rs text, bik text) is 'Проверяет, что переданная строка является расчётным счётом';

--TEST
DO $$
begin
    --positive
    assert public.is_client_account('40817810099910004312');
    assert public.is_client_account('40702810900000002851', '044030827');
    assert public.is_client_account('40701810000001002118', '044106001');

    --negative
    assert not public.is_client_account('4234567890123456789');
    assert not public.is_client_account('423456789012345678901');
    assert not public.is_client_account('4234567890123456789*');
    assert not public.is_client_account('40702810000000002851', '044030827');
    assert not public.is_client_account('40702810100000002851', '044030827');
    assert not public.is_client_account('40702810200000002851', '044030827');
    assert not public.is_client_account('40702810300000002851', '044030827');
    assert not public.is_client_account('40702810400000002851', '044030827');
    assert not public.is_client_account('40702810500000002851', '044030827');
    assert not public.is_client_account('40702810600000002851', '044030827');
    assert not public.is_client_account('40702810700000002851', '044030827');
    assert not public.is_client_account('40702810800000002851', '044030827');
END $$;

