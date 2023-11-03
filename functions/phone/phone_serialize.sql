create or replace function public.phone_serialize(
    country_code text,  --код страны в любом формате или NULL
    area_code text,     --код зоны в любом формате или NULL
    local_number text,   --локальный номер телефона в любом формате или NULL
    separator text default '(-.-)' -- набор символов в разделителе должен быть таким,
                                   -- чтобы корректно работали функции phone_normalize() и phone_parse()
)
    returns text --not null
    immutable
    --returns null on null input
    parallel safe
    language sql
    set search_path = ''
as
$$
    select concat_ws('', country_code, separator, area_code, separator, local_number);
$$;

comment on function public.phone_serialize(
    country_code text,
    area_code text,
    local_number text,
    separator text
) is 'Сериализует номер телефона из трёх полей в одно по специальному разделителю';

------------------------------------------------------------------------------------------------------------------------

create or replace function public.phone_serialize(
    country_code int,   --код страны в любом формате или NULL
    area_code text,     --код зоны в любом формате или NULL
    local_number text,   --локальный номер телефона в любом формате или NULL
    separator text default '(-.-)' -- набор символов в разделителе должен быть таким,
                                   -- чтобы корректно работали функции phone_normalize() и phone_parse()
)
    returns text
    immutable
    --returns null on null input
    parallel safe
    language sql
as
$$
    select public.phone_serialize(country_code::text, area_code, local_number);
$$;

comment on function public.phone_serialize(
    country_code int,
    area_code text,
    local_number text,
    separator text
) is 'Сериализует номер телефона из трёх полей в одно по специальному разделителю';


------------------------------------------------------------------------------------------------------------------------
--TEST
do $$
begin
    assert public.phone_serialize(7, '965', '1234567') = '7(-.-)965(-.-)1234567';
    assert public.phone_serialize('+7', '965', '1234567') = '+7(-.-)965(-.-)1234567';
    assert public.phone_serialize('', '', '') = '(-.-)(-.-)';
    assert public.phone_serialize(null::text, null, null) = '(-.-)(-.-)';
    assert public.phone_serialize(null::int, null, null) = '(-.-)(-.-)';

    assert public.phone_serialize('7', '965', '1234567', '') = '79651234567';
    assert public.phone_serialize('7', '965', '1234567', null) = '79651234567';
end;
$$;
