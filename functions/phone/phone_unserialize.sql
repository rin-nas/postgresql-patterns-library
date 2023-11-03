create or replace function public.phone_unserialize(
    phone text, --номер телефона, сериализованный функцией phone_serialize()

    country_code_example text, --nullable
    area_code_example text,    --nullable
    local_number_example text, --nullable

    separator text default '(-.-)', -- набор символов в разделителе должен быть таким же, как при сериализации

    country_code out text, --nullable
    area_code out text,    --nullable
    local_number out text  --nullable
)
    returns record
    immutable
    --returns null on null input
    parallel safe
    language plpgsql
    set search_path = ''
as
$$
declare
    parts text[] not null default array[]::text[];
begin

    if phone is null then
        return;
    end if;

    parts := string_to_array(phone, separator);

    if array_length(parts, 1) != 3 then
        raise exception using
            message = 'Cannot split phone into 3 parts by separator!',
            detail  = format('Phone = "%s", separator = "%s"', phone, separator),
            hint    = 'Serialized phone was broken or another seperator used?';
    end if;

    country_code := parts[1];
    area_code    := parts[2];
    local_number := parts[3];

    if nullif(country_code_example, '') is null then
        if country_code != '' then
            raise exception using
                message = 'Unconsistent unserialized "country_code" value',
                detail  = format('Emtpy string expected, but "%s" given', country_code);
        end if;
        country_code = country_code_example;
    end if;

    if nullif(area_code_example, '') is null then
        if area_code != '' then
            raise exception using
                message = 'Unconsistent unserialized "area_code" value',
                detail  = format('Emtpy string expected, but "%s" given', area_code);
        end if;
        area_code = area_code_example;
    end if;

    if nullif(local_number_example, '') is null then
        if local_number != '' then
            raise exception using
                message = 'Unconsistent unserialized "local_number" value',
                detail  = format('Emtpy string expected, but "%s" given', local_number);
        end if;
        local_number = local_number_example;
    end if;

end
$$;

comment on function public.phone_unserialize(
    phone text,

    country_code_example text,
    area_code_example text,
    local_number_example text,

    separator text,

    country_code out text,
    area_code out text,
    local_number out text
) is 'Десериализует номер телефона из одного поля в три по специальному разделителю';

------------------------------------------------------------------------------------------------------------------------

create or replace function public.phone_unserialize(
    phone text, --номер телефона, сериализованный функцией phone_serialize()

    country_code_example int, --nullable
    area_code_example text,    --nullable
    local_number_example text, --nullable

    separator text default '(-.-)', -- набор символов в разделителе должен быть таким же, как при сериализации

    country_code out int, --nullable
    area_code out text,    --nullable
    local_number out text  --nullable
)
    returns record
    immutable
    --returns null on null input
    parallel safe
    language sql
as
$$
    select u.country_code::int, u.area_code, u.local_number
    from phone_unserialize(phone,
                                  country_code_example::text, area_code_example, local_number_example,
                                  separator) as u;
$$;

comment on function public.phone_unserialize(
    phone text,

    country_code_example int,
    area_code_example text,
    local_number_example text,

    separator text,

    country_code out int,
    area_code out text,
    local_number out text
) is 'Десериализует номер телефона из одного поля в три по специальному разделителю';

------------------------------------------------------------------------------------------------------------------------
--TEST
do $$
begin

    assert not exists(
        with t (country_code, area_code, local_number) as (
            values ('+7', '965', '123-45-67'),
                   ('+79651234567', null, null),
                   (null::text, '+79651234567', null),
                   (null::text, null, '+79651234567'),
                   ('', '', ''),
                   (null::text, null, null)
        )
        select t.*, s.*, u.*
        from t
        cross join public.phone_serialize(t.country_code, t.area_code, t.local_number) as s(phone)
        cross join public.phone_unserialize(s.phone, t.country_code, t.area_code, t.local_number) as u
        where t is distinct from u
    );

    assert not exists(
        with t (country_code, area_code, local_number) as (
            values (7, '965', '123-45-67'),
                   (null::int, null, null)
        )
        select t.*, s.*, u.*
        from t
        cross join public.phone_serialize(t.country_code, t.area_code, t.local_number) as s(phone)
        cross join public.phone_unserialize(s.phone, t.country_code, t.area_code, t.local_number) as u
        where t is distinct from u
    );

end;
$$;
