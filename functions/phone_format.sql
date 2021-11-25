create or replace function phone_format(
    country_code text,
    area_code text,
    local_number text,
    phone_example text default '+12223334455' --E.164
)
    returns text
    stable
    returns null on null input
    parallel safe
    language sql
as
$$
select
    concat_ws('', m[1], country_code, m[2], area_code, m[3], local_number)
from
    regexp_match(phone_example, '^(\D*)\d{1,3}(\D*)\d+(\D*)') as r(m);
$$;

comment on function phone_format(
    country_code text,
    area_code text,
    local_number text,
    phone_example text
) is 'Форматирует номер телефона по образцу';


--TEST
do $$
begin
    --positive
    assert phone_format('7', '965', '1234567') = '+79651234567';

    assert phone_format('7', '965', '1234567',  '00000000000') = '79651234567';
    assert phone_format('7', '965', '1234567',  '0 0000000000') = '7 9651234567';
    assert phone_format('7', '965', '1234567',  '0 000 0000000') = '7 965 1234567';
    assert phone_format('7', '965', '1234567',  '0 (000) 0000000') = '7 (965) 1234567';
    assert phone_format('7', '965', '1234567', '0000 000-00-00') = '7965 1234567';

    assert phone_format('7', '965', '1234567',  '+00000000000') = '+79651234567';
    assert phone_format('7', '965', '1234567',  '+0-0000000000') = '+7-9651234567';
    assert phone_format('7', '965', '1234567',  '+0(000)000-00-00') = '+7(965)1234567';
    assert phone_format('7', '965', '1234567',  '+0 (000) 000-00-00') = '+7 (965) 1234567';
    assert phone_format('7', '965', '1234567',  '+(0000) 000-00-00') = '+(7965) 1234567';

    --negative
    assert phone_format('7', '965', null) is null;
end;
$$;
