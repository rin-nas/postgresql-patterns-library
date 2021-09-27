create or replace function phone_parse(
    phone text,
    country_code out text,
    area_code out text,
    local_number out text
)
    -- парсит номер телефона в международном формате: +<countryCode><space><areaCode><space><localNumber>
    -- для маленьких стран <areaCode> может отсутствовать
    -- возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса)
    returns record
    stable
    returns null on null input
    parallel safe
    language sql
as
$$
--https://www.cm.com/blog/how-to-format-international-telephone-numbers/
with t as (
    -- грубая проверка проверка синтаксиса и нормализация номера телефона
    select n
    from trim(regexp_replace(phone, '[+ ()\-.]+', ' ', 'g')) as n
    where octet_length(phone) between (8+1/*+*/) and (15*2)
      and phone ~ '\+\d'
)
select p[1] as country_code,
       p[2] as area_code,
       p[3] as local_number
from t cross join regexp_match(t.n, '^
                                      (\d{1,3})\x20   #country_code
                                      (?:(\d+)\x20)?  #area_code
                                      (\d+)           #local_number
                                     $', 'x') as p
-- проверяем кол-во цифр
where octet_length(replace(t.n, ' ', ''))
          between 8 --https://stackoverflow.com/questions/14894899/what-is-the-minimum-length-of-a-valid-international-phone-number
          and 15; --https://en.wikipedia.org/wiki/E.164 and https://en.wikipedia.org/wiki/Telephone_numbering_plan
$$;

-- TEST
do $$
    begin
        --positive
        assert (select country_code = '375'
                           and area_code = '17'
                           and local_number = '1234567'
                from phone_parse('+375 17 1234567'));
        assert (select country_code = '677'
                           and area_code is null
                           and local_number = '12345'
                from phone_parse('+677 12345'));
        assert (phone_parse('+375 17 1234567')).country_code = '375';
        --negative
        assert phone_parse('+375171234567') is null; --syntax
        assert phone_parse('+677 1234') is null; --minimum length
        assert phone_parse('+375 17 12345671234567890') is null; --maximum length
    end
$$;
