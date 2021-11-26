create or replace function phone_format(
    country_code text, --только цифры, не пусто
    area_code text, --только цифры или пусто
    local_number text, --только цифры, не пусто
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
    --to_json(m),
    trim(regexp_replace(concat(
        m[1],
        country_code,
        m[3],
        left(area_code || local_number, octet_length(m[4])),
        m[5],
        right(area_code || local_number, -1 * octet_length(m[4]))
    ), '  +', ' ', 'g'))
from
    regexp_match(trim(phone_example), '^(\D*)(\d+)(\D*)(\d+)(\D*)') as r(m);
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

    assert phone_format('7', '965', '1234567',  ' 00000000000 ') = '79651234567';
    assert phone_format('7', '965', '1234567',  '0  0000000000') = '7 9651234567';
    assert phone_format('7', '965', '1234567',  '0 000 0000000') = '7 965 1234567';
    assert phone_format('7', '965', '1234567',  '0 (000) 0000000') = '7 (965) 1234567';

    assert phone_format('7', '965', '1234567',  '+00000000000') = '+79651234567';
    assert phone_format('7', '965', '1234567',  '+0-0000000000') = '+7-9651234567';
    assert phone_format('7', '965', '1234567',  '+0(000)000-00-00') = '+7(965)1234567';
    assert phone_format('7', '965', '1234567',  '+0 (000) 000-00-00') = '+7 (965) 1234567';

    --negative
    assert phone_format('7', '965', null) is null;
end;
$$;
