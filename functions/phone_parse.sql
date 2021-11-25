-- TODO add support for https://datatracker.ietf.org/doc/html/rfc3966  (see https://habr.com/ru/post/278345/)

create or replace function phone_parse(
    phone text,
    country_code out text,
    area_code out text,
    local_number out text
)
    /*
    Парсит номер телефона в международном формате E.164 или в локальном формате.
    Для маленьких стран area_code может отсутствовать.
    Возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса).
    */
    returns record
    stable
    returns null on null input
    parallel safe
    language sql
as
$$
with t as (
    -- грубая проверка проверка синтаксиса и нормализация номера телефона
    select array_to_string((string_to_array(n, ' '))[1:3], ' ') ||
           array_to_string((string_to_array(n, ' '))[4:], '') as n
    from trim(regexp_replace(phone, '(^ *\+|[ ()\-./]+)', ' ', 'g')) as n
    where octet_length(phone) between (8 + 1/*+*/) and (15 * 2/*учитывам пробелы*/)
      -- начинается со знака "+" и цифры (E.164 с возможными разделителями групп цифр)
      -- или начинается с national prefix и пробела
      -- или содержит только цифры (E.164 без знака "+")
      and phone ~ '^\+\d|^(?:[018]|0[126]|04[45])\x20|^\d+$'
)
select trim(replace(p[1], '8 ', '7')) as country_code,
       nullif(p[2], '') as area_code,
       trim(p[3])       as local_number
from t cross join regexp_match(t.n,
                               -- регулярное выражение для захвата телефонного кода страны сгенерировано автоматически, см. extra/phone.sql
                               '^
                                (
                                  #calling code:
                                  [17]
                                  |2(?:[07]|1[1-368]|[2-46]\d|5[0-8]|9[017-9])
                                  |3(?:[0-469]|5\d|7[0-8]|8[0-35-79])
                                  |4(?:[013-9]|2[013])
                                  |5(?:[09]\d|[1-8])
                                  |6(?:[0-6]|7[02-9]|8[0-35-9]|9[0-2])
                                  |8(?:[07][08]|[1246]|5[02356]|8[0-368])
                                  |9(?:[0-58]|6[0-8]|7[0-79]|9[2-68])
                                  #national prefix:
                                  |(?:[018]|0[126]|04[45])\x20 #
                                )  #1 country_code
                                \x20?
                                (\d*)  #2 area_code
                                (\x20\d+|\d{7})  #3 local_number
                               $', 'x') as p
-- проверяем кол-во цифр
where octet_length(replace(t.n, ' ', ''))
          between 8 --https://stackoverflow.com/questions/14894899/what-is-the-minimum-length-of-a-valid-international-phone-number
          and 15; --https://en.wikipedia.org/wiki/E.164 and https://en.wikipedia.org/wiki/Telephone_numbering_plan
$$;

comment on function phone_parse(
    phone text,
    country_code out text,
    area_code out text,
    local_number out text
) is $$
Парсит номер телефона в международном формате E.164 или в локальном формате.
Для маленьких стран area_code может отсутствовать.
Возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса).
$$;

-- TEST
do $$
    begin
        --positive
        assert (select country_code = '7'
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('74991234567'));
        assert (select country_code = '7'
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+7 (499) 1234567'));
        assert (select country_code = '7'
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+7 4991234567'));
        assert (select country_code = '7'
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+7499 1234567'));
        assert (select country_code = '7'
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+74991234567'));
        assert (select country_code = '7'
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('8 4991234567'));

        assert (select country_code = '54'
                   and area_code = '9'
                   and local_number = '2982123456'
                from phone_parse('+54 9 2982 123456'));

        assert (select country_code = '375'
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('+375 17 123-45-67'));
        assert (select country_code = '375'
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('+375 17 1234567'));
        assert (select country_code = '375'
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('+375171234567'));
        assert (select country_code = '375'
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('375171234567'));

        assert (select country_code = '373'
                   and area_code = '68'
                   and local_number = '007777'
                from phone_parse('+373 68 007777'));

        assert (select country_code = '971'
                   and area_code = '2'
                   and local_number = '6721797'
                from phone_parse('+971 2 672 1797'));

        assert (select country_code = '677'
                   and area_code is null
                   and local_number = '12345'
                from phone_parse('+677 12345'));
        --negative
        assert phone_parse('+677 1234') is null; --minimum length
        assert phone_parse('+375 17 12345671234567890') is null; --maximum length
    end
$$;
