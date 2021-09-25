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
--https://www.cm.com/blog/how-to-format-international-telephone-numbers/
select t[1] as country_code,
       t[2] as area_code,
       t[3] as local_number
from regexp_match(phone, '^\+(\d{1,3}) (\d+) (\d+)$', '') as t
where length(regexp_replace(phone, '\D+', '', 'g'))
      between 7 --https://stackoverflow.com/questions/14894899/what-is-the-minimum-length-of-a-valid-international-phone-number
      and 15 --https://en.wikipedia.org/wiki/E.164 and https://en.wikipedia.org/wiki/Telephone_numbering_plan
$$;

--TEST
select * from phone_parse('+375 17 1234567') as t;
select (phone_parse('+375 17 1234567')).country_code as t;

select t.country_code is not null
       and t.area_code is not null
       and t.local_number is not null as is_phone
from phone_parse('+375 17 1234567') as t;
