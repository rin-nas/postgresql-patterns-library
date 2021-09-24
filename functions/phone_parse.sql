create or replace function phone_parse(
    phone text,
    country_code out text,
    area_code out text,
    local_number out text
)
    -- парсит номер телефона в международном формате: +<countryCode><space><areaCode><space><localNumber>
    -- возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса)
    returns record
    stable
    returns null on null input
    parallel safe
    language sql
as
$$
select t[1] as country_code,
       t[2] as area_code,
       t[3] as local_number
from regexp_match(phone, '^\+(\d+) (\d+) (\d+)$', '') as t
$$;

--TEST
select * from phone_parse('+375 17 1234567') as t;
select (phone_parse('+375 17 1234567')).country_code as t;

select t.country_code is not null
       and t.area_code is not null
       and t.local_number is not null as is_phone
from phone_parse('+375 17 1234567') as t;
