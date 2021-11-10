create or replace function phone_normalize(
    country_code int,
    area_code text,
    local_number text
)
    returns text
    stable
    --returns null on null input
    parallel safe
    language plpgsql
as
$$
declare
    phone text;
begin
    if country_code not between 0 and 999
        or (area_code is null and local_number is null)
    then
        return null;
    end if;

    area_code    := trim(regexp_replace(area_code,    '(?:^\D+|\D+$|[ ()\-.]+|&(?:ndash|minus);)', ' ', 'g'));
    local_number := trim(regexp_replace(local_number, '(?:^\D+|\D+$|[ ()\-.]+|&(?:ndash|minus);)', ' ', 'g'));

    phone := replace(concat_ws('', area_code, local_number), ' ', '');
    phone := regexp_replace(phone, '(?<![а-яё])[сc]\d+[дп]о\d+ч?', '');
    phone := regexp_replace(phone, '(?<=\d)(доб|вн|ext)\d+$', ''); --добавочный номер
    phone := regexp_replace(phone, '(?<=\d)(/\d\d)+$', ''); --альтернативные номера через слэш
    phone := replace(phone, '/', '');
    --raise notice 'stage 1: %', phone;

    if phone !~ '^\d+$'
    then
        return null;
    end if;

    if country_code in (7, 8) and phone ~ '^[78]\d{10}$'
    then
        country_code := null; --deduplication
    end if;

    phone := concat_ws(' ', country_code, area_code, local_number);
    phone := regexp_replace(phone, '^[78] [78] ', '7'); --deduplication
    phone := replace(phone, ' ', '');
    phone := regexp_replace(phone, '(?<![а-яё])[сc]\d+[дп]о\d+ч?', '');
    phone := regexp_replace(phone, '(?<=\d)(доб|вн|ext)\d+$', ''); --добавочный номер
    phone := regexp_replace(phone, '(?<=\d)(/\d\d)+$', ''); --альтернативные номера через слэш
    phone := replace(phone, '/', '');
    --raise notice 'stage 2: %', phone;

    if phone ~ '(\d)\1{8}' --все цифры одинаковые
    then
        return null;
    end if;

    if country_code is null and octet_length(phone) = 10
    then
        phone = '7' || phone;
    end if;

    if octet_length(phone) not
        between 8 --https://stackoverflow.com/questions/14894899/what-is-the-minimum-length-of-a-valid-international-phone-number
        and 15  --https://en.wikipedia.org/wiki/E.164 and https://en.wikipedia.org/wiki/Telephone_numbering_plan)
    then
        return null;
    end if;

    return '+' || regexp_replace(phone, '^8', '7');
end;
$$;

comment on function phone_normalize(
    country_code int,
    area_code text,
    local_number text
) is $$
Принимает на входе номер телефона в 3-х полях, каждое из которых может быть null!
Возвращает номер телефона в международном формате E.164, например: +79651234567
При необходимости, пытается исправить ошибки:
  * заменяет национальный префикс 8 на код страны 7
  * дополняет номер телефона кодом страны 7, если его нехватает
  * удаляет дубликаты национального префикса или кода страны
  * удаляет все слова вначале и в конце (например, ФИО), добавочный номер, альтернативный номер и диапазон времени звонка
Возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса).
$$;

--TEST
do $$
    begin
        --positive
        assert phone_normalize(null,null,'+7 (977) 123-45-67') = '+79771234567';
        assert phone_normalize(null,null,'+ 7 (977) 123-45-67') = '+79771234567';
        assert phone_normalize(null,null,'++ 7 (977) 123-45-67 доб 123 Мария') = '+79771234567';
        assert phone_normalize(null,null,'+ 7 (977) 123-45-67 вн. 123') = '+79771234567';
        assert phone_normalize(null,null,'+ 7 (977) 123-45-67 моб.') = '+79771234567';
        assert phone_normalize(null,null,'8/977/1234567') = '+79771234567';
        assert phone_normalize(null,null,'8 (812) 123&ndash;45&minus;67') = '+78121234567';
        assert phone_normalize(null,null,'моб.т. + 7 (977) 123-45-67 ') = '+79771234567';
        assert phone_normalize(null,null,' моб. 8 /977/ 123-45-67/69/70 Мария/Иван ') = '+79771234567';
        assert phone_normalize(null,null,' моб. 8 (977) 123-45-67/69 Мария Петровна ') = '+79771234567';

        assert phone_normalize(null,null,'8(977)123-45-67 с 12.00 до 22.00') = '+79771234567';
        assert phone_normalize(null,null,'8(977)123-45-67 с 9 по 11 ч. строго') = '+79771234567';

        assert phone_normalize(null,null,'89771234567') = '+79771234567';
        assert phone_normalize(null,null,'(977) 123-45-67') = '+79771234567';
        assert phone_normalize(null,'8 977','123 45 67') = '+79771234567';
        assert phone_normalize(null,'977','123 45 67') = '+79771234567';
        assert phone_normalize(null,'831 66 1-23-45',null) = '+78316612345';

        assert phone_normalize(7,'','8 977 123 45 67') = '+79771234567';
        assert phone_normalize(7,'8 977','123 45 67') = '+79771234567';
        assert phone_normalize(8,'7 977','123 45 67') = '+79771234567';
        assert phone_normalize(7,'977','1234567') = '+79771234567';
        assert phone_normalize(8,null,'8 9771234567') = '+79771234567';

        --negative
        assert phone_normalize(-1,'977','1234567') is null;
        assert phone_normalize(1000,'977','1234567') is null;
        assert phone_normalize(null,null,null) is null;
        assert phone_normalize(null,null,null) is null;
        assert phone_normalize(null,' ',' ') is null;
        assert phone_normalize(null,null,'     123456    ') is null;
        assert phone_normalize(null,'     123456    ',null) is null;
        assert phone_normalize(null,null, '1234567890123456') is null;
        assert phone_normalize(null,null, '8x977_1234567') is null;
    end;
$$;
