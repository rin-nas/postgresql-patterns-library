create or replace function phone_normalize(
    country_code int,
    area_code text,
    local_number text
)
    /*
    Возвращает номер телефона в международном формате E.164.
    При необходимости, пытается исправить ошибки:
      * заменяет национальный префикс 8 на код страны 7
      * дополняет номер телефона кодом страны 7
      * удаляет дубликаты национального префикса или кода страны
    Возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса).
    */
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
    then
        return null;
    end if;

    area_code    := trim(regexp_replace(area_code,    '\D+', ' ', 'g'));
    local_number := trim(regexp_replace(local_number, '\D+', ' ', 'g'));

    if country_code in (7, 8) and replace(concat_ws('', area_code, local_number), ' ', '') ~ '^[78]\d{10}$'
    then
        area_code := substr(area_code, 2);
    end if;

    phone := concat_ws(' ', country_code, area_code, local_number);
    phone := regexp_replace(phone, '^[78] [78] ', '7 ');
    phone := replace(phone, ' ', '');

    if phone ~ '(\d)\1{8}'
    then
        return null;
    end if;

    if country_code is null and octet_length(phone) < 11
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

--TEST
do $$
    begin
        --positive
        assert phone_normalize(null,null,'+7 (977) 123-45-67') = '+79771234567';
        assert phone_normalize(null,null,'89771234567') = '+79771234567';
        assert phone_normalize(null,null,'(977) 123-45-67') = '+79771234567';
        assert phone_normalize(null,'8 977','123 45 67') = '+79771234567';
        assert phone_normalize(null,'977','123 45 67') = '+79771234567';
        assert phone_normalize(null,'831 66 1-23-45',null) = '+78316612345';

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
    end;
$$;
