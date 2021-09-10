create function phone_parse(phone text)
    -- парсит номер телефона в международном формате: +<countryCode><space><areaCode><space><localNumber>
    -- возвращает null, если строка не является номером телефона (минимальная проверка синтаксиса)
    returns table (
        country_code text,
        area_code text,
        local_number text
    )
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
select t.country_code, t.area_code, t.local_number
from phone_parse('+375 17 1234567') as t;

select (phone_parse('+375 17 1234567')).country_code as t;
