create or replace function is_snils(str text)
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
    coefficients constant int[] not null default array[9, 8, 7, 6, 5, 4, 3, 2, 1];
    i int default 1;
begin

    --https://ru.wikipedia.org/wiki/Страховой_номер_индивидуального_лицевого_счёта
    if octet_length(str) != 11 or str ~ '\D' then
        return false;
    end if;

    -- https://ru.wikipedia.org/wiki/Контрольное_число#Страховой_номер_индивидуального_лицевого_счёта_(Россия)
    if left(str, 9) <= '001001998' then
        return true;
    end if;

    digits := string_to_array(str, null)::int[];

    while coefficients[i] is not null
    loop
        checksum := checksum + (coefficients[i] * digits[i]);
        i := i + 1;
    end loop;

    if checksum > 101 then
        checksum := checksum % 101;
    end if;

    if checksum in (100, 101) then
        checksum := 0;
    end if;

    return checksum = right(str, 2)::int;

end;
$func$;

comment on function is_snils(str text) is 'Проверяет, что переданная строка является СНИЛС (страховой номер индивидуального лицевого счёта)';


--TEST
DO $$
BEGIN
    --positive
    assert is_snils('00000000000');
    assert is_snils('00000000001');
    assert is_snils('00000000002');
    assert is_snils('00000000003');
    assert is_snils('11223344595');
    assert is_snils('08765430300');
    assert is_snils('08765430200');
    assert is_snils('08765430300');
    assert is_snils('08675430300');

    --negative
    assert not is_snils('1234567890');
    assert not is_snils('123456789012');
    assert not is_snils('12345678901');
    assert not is_snils('12345678902');
    assert not is_snils('12345678903');
    assert not is_snils('12345678904');
    assert not is_snils('12345678905');
    assert not is_snils('12345678906');
    assert not is_snils('12345678907');
    assert not is_snils('12345678908');
    assert not is_snils('12345678909');
    assert not is_snils('62602903622');
END $$;
