-- TODO add support for https://datatracker.ietf.org/doc/html/rfc3966  (see https://habr.com/ru/post/278345/)

create or replace function phone_parse(
    /*
    Номер телефона в международном или локальном формате, допускающим разделение групп цифр пробелами, скобками и дефисами
    Номер телефона должен:
        * начинаться со знака "+" и цифры (E.164 с возможными разделителями групп цифр)
        * или начинаться с national prefix и не цифры
        * или содержать только цифры (E.164 без знака "+")
    Номер телефона НЕ должен иметь какие-либо преписки в начале ("моб. тел.") и дописки в конце ("с 9 до 18")
    Номер телефона в любом формате умеет обрабатывать функция phone_normalize()
    */
    phone text,
    allow_calling_codes       bool default true,  --разрешить номера телефонов с используемыми кодами стран
    allow_national_prefixes   bool default true,  --разрешить номера телефонов с национальными префиксами
    allow_spare_codes         bool default false, --разрешить номера телефонов с неназначенными (резервными) кодами стран
    begins_special_spare_code bool default false, --Начинается со специального резервного кода
                                                  --210 (для валидных номеров) или 214 (для невалидных номеров).
                                                  --Используется в обезличивании персональных данных для уникальных
                                                  --номеров телефонов в качестве временного номера телефона.
    country_code out int,
    area_code out text,   --только цифры или пусто
    local_number out text --только цифры
)
    returns record
    immutable
    returns null on null input
    parallel safe
    language sql
as
$$
with t as (
    -- грубая проверка проверка синтаксиса и нормализация номера телефона
    select array_to_string((string_to_array(n, ' '))[1:3], ' ') ||
           array_to_string((string_to_array(n, ' '))[4:], '') as n,
       '^
        ( #1 special spare country code
            $21[04]  #valid (210) or invalid (214) phone number ($ is special marker, see below!)
            \x20?
        )?
        ( #2 country_code
          ( #3 calling code
            #регулярное выражение для захвата телефонного кода страны сгенерировано автоматически, см. extra/phone.sql
            [17]
            |2(?:[07]|1[1-368]|[2-46]\d|5[0-8]|9[017-9])
            |3(?:[0-469]|5\d|7[0-8]|8[0-35-79])
            |4(?:[013-9]|2[013])
            |5(?:[09]\d|[1-8])
            |6(?:[0-6]|7[02-9]|8[0-35-9]|9[0-2])
            |8(?:[07][08]|[1246]|5[02356]|8[0-368])
            |9(?:[0-58]|6[0-8]|7[0-79]|9[2-68])
          )
          | ( #4 national prefix
              [018]|0[126]|04[45]
            )\x20
          | ( #5 spare_code
              2(?:1[04579]|59|8\d|9[2-6])
              |384
              |42[24-9]
              |69[3-9]
              |8(?:0[1-79]|3\d|5[147-9]|7[1-4]|8[4579]|9\d)
              |9(?:78|90)
            )
        )
        (?:
            ((?:\x20?\d)*)  #6 area_code
            ((?:\x20?\d){7})  #7 local_number long
          | ((?:\x20?\d){5,6}) #8 local_number short
        )
        $' as re
    from trim(regexp_replace(phone,
                             '(?:^\+|[ ()\-./]+)',
                             case when left(phone, 1) = '+' then '' else ' ' end, --speed improves
                             'g')) as n
    where octet_length(phone) between (8 + 1/*+*/) and (15 * 2/*учитывам пробелы*/)
      -- начинается со знака "+" и цифры (E.164 с возможными разделителями групп цифр)
      -- или начинается с national prefix и не цифры
      -- или содержит только цифры (E.164 без знака "+")
      and phone ~ '^\+\d|^(?:[018]|0[126]|04[45])\D|^\d+$'
)
--select * from t;
select trim(replace(p[2], '8 ', '7'))::int as country_code,
       replace(coalesce(p[6], ''), ' ', '') as area_code, -- do not convert empty sting to null!
       replace(coalesce(p[7], p[8]), ' ', '') as local_number
from t
cross join regexp_match(t.n,
                        case when begins_special_spare_code then regexp_replace(t.re, '\$(?=21\[04\])', '')
                             else t.re
                        end,
                        'x') as p
-- проверяем кол-во цифр
where octet_length(replace(t.n, ' ', ''))
          between 8 --https://stackoverflow.com/questions/14894899/what-is-the-minimum-length-of-a-valid-international-phone-number
          and 15 --https://en.wikipedia.org/wiki/E.164 and https://en.wikipedia.org/wiki/Telephone_numbering_plan
      and p[2] is not null --country_code
      and coalesce(p[7], p[8]) is not null --local_number
      and (allow_calling_codes     or p[3] is null)
      and (allow_national_prefixes or p[4] is null)
      and (allow_spare_codes       or p[5] is null)
      and (not begins_special_spare_code or p[1] is not null);
$$;

comment on function phone_parse(
    phone text,
    allow_calling_codes     bool,
    allow_national_prefixes bool,
    allow_spare_codes       bool,
    begins_special_spare_code bool,
    country_code out text,
    area_code    out text,
    local_number out text
) is $$
    Разбирает номер телефона в международном формате E.164 или в локальном формате.
    Для маленьких стран area_code может отсутствовать.
    Возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса).
$$;

-- TEST
do $$
    begin
        --positive
        assert (select country_code = 7
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('74991234567'));
        assert (select country_code = 7
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+7 (499) 1234567'));
        assert (select country_code = 7
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+7 4991234567'));
        assert (select country_code = 7
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+7499 1234567'));
        assert (select country_code = 7
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('+74991234567'));
        assert (select country_code = 7
                   and area_code = '499'
                   and local_number = '1234567'
                from phone_parse('8 4991234567'));

        assert (select country_code = 54
                   and area_code = '9298'
                   and local_number = '2123456'
                from phone_parse('+54 9 2982 123456'));

        assert (select country_code = 375
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('+375 17 123-45-67'));
        assert (select country_code = 375
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('+375 17 1234567'));
        assert (select country_code = 375
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('+375171234567'));
        assert (select country_code = 375
                   and area_code = '17'
                   and local_number = '1234567'
                from phone_parse('375171234567'));

        assert (select country_code = 373
                   and area_code = '6'
                   and local_number = '8007777'
                from phone_parse('+373 68 007777'));

        assert (select country_code = 971
                   and area_code = '2'
                   and local_number = '6721797'
                from phone_parse('+971 2 672 1797'));

        -- short phone number
        assert (select country_code = 677
                   and area_code  = ''
                   and local_number = '12345'
                from phone_parse('+677 12345'));

        -- short phone number
        assert (select country_code = 677
                   and area_code  = ''
                   and local_number = '123456'
                from phone_parse('+677 123456'));

        -- special spare code
        assert (select country_code = 210
                           and area_code  = '7906'
                           and local_number = '1234567'
                from phone_parse('+21079061234567', true, true, true, false));
        assert (select country_code = 7
                           and area_code  = '906'
                           and local_number = '1234567'
                from phone_parse('+21479061234567', true, true, true, true));

        --negative
        assert phone_parse('74991234567', false, true, true) is null;
        assert phone_parse('8 4991234567', true, false, true) is null;
        assert phone_parse('210 4991234567', true, true, false) is null;
        assert phone_parse('9991234567') is null; --invalid phone number
        assert phone_parse('+677 1234') is null; --minimum length
        assert phone_parse('+375 17 12345671234567890') is null; --maximum length
    end
$$;
