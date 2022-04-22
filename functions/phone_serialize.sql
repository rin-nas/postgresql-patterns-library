create or replace function phone_serialize(
    country_code text,  --код страны в любом формате или NULL
    area_code text,     --код зоны в любом формате или NULL
    local_number text,   --локальный номер телефона в любом формате или NULL
    separator text default '(-.-)' -- набор символов в разделителе должен быть таким,
                                   -- чтобы корректно работали функции phone_normalize() и phone_parse()
)
    returns text --not null
    stable
    --returns null on null input
    parallel safe
    language plpgsql
    cost 2
as
$$
begin
    return concat_ws('', country_code, separator, area_code, separator, local_number);
end
$$;

comment on function phone_serialize(
    country_code text,
    area_code text,
    local_number text,
    separator text
) is 'Сериализует номер телефона из трёх полей в одно по специальному разделителю';

------------------------------------------------------------------------------------------------------------------------

create or replace function phone_serialize(
    country_code int,   --код страны в любом формате или NULL
    area_code text,     --код зоны в любом формате или NULL
    local_number text,   --локальный номер телефона в любом формате или NULL
    separator text default '(-.-)' -- набор символов в разделителе должен быть таким,
                                   -- чтобы корректно работали функции phone_normalize() и phone_parse()
)
    returns text
    stable
    --returns null on null input
    parallel safe
    language sql
as
$$
    select phone_serialize(country_code::text, area_code, local_number);
$$;

comment on function phone_serialize(
    country_code int,
    area_code text,
    local_number text,
    separator text
) is 'Сериализует номер телефона из трёх полей в одно по специальному разделителю';


------------------------------------------------------------------------------------------------------------------------
--TEST
do $$
begin
    assert phone_serialize(7, '965', '1234567') = '7(-.-)965(-.-)1234567';
    assert phone_serialize('+7', '965', '1234567') = '+7(-.-)965(-.-)1234567';
    assert phone_serialize('', '', '') = '(-.-)(-.-)';
    assert phone_serialize(null::text, null, null) = '(-.-)(-.-)';
    assert phone_serialize(null::int, null, null) = '(-.-)(-.-)';

    assert phone_serialize('7', '965', '1234567', '') = '79651234567';
    assert phone_serialize('7', '965', '1234567', null) = '79651234567';
end;
$$;

