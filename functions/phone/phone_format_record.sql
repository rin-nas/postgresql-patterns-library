create or replace function phone_format_record(
    in_country_code text,
    in_area_code text,
    in_local_number text,

    country_code_example text,
    area_code_example text,
    local_number_example text,

    country_code out text,
    area_code out text,
    local_number out text
)
    returns record
    stable
    --returns null on null input
    parallel safe
    language sql
    set search_path = ''
as
$$;
select
    case when country_code_example is null or country_code_example = '' then country_code_example
         else phone_format(in_country_code, country_code_example) end as country_code,

    left(case when area_code_example is null or area_code_example = '' then area_code_example
              when area_code_example ~ '^\+\d|^\d+\D+\d' then phone_format(concat_ws('', in_country_code, in_area_code), area_code_example)
              else phone_format(in_area_code, area_code_example) end,
         32) as area_code,

    left(phone_format(
            concat_ws('',
                      case when area_code_example is null or area_code_example = '' then in_area_code else '' end,
                      in_local_number),
            local_number_example
        ), 32) as local_number;
$$;

comment on function phone_format_record(
    in_country_code text,
    in_area_code text,
    in_local_number text,

    country_code_example text,
    area_code_example text,
    local_number_example text,

    country_code out text,
    area_code out text,
    local_number out text
) is 'Форматирует номер телефона по образцу';

------------------------------------------------------------------------------------------------------------------------

create or replace function phone_format_record(
    in_country_code int,
    in_area_code text,
    in_local_number text,

    country_code_example int,
    area_code_example text,
    local_number_example text,

    country_code out int,
    area_code out text,
    local_number out text
)
    returns record
    stable
    --returns null on null input
    parallel safe
    language sql
as
$$;
    select t.country_code::int, t.area_code, t.local_number
    from phone_format_record(in_country_code::text, in_area_code, in_local_number,
                                    country_code_example::text, area_code_example, local_number_example) as t;
$$;

comment on function phone_format_record(
    in_country_code int,
    in_area_code text,
    in_local_number text,

    country_code_example int,
    area_code_example text,
    local_number_example text,

    country_code out int,
    area_code out text,
    local_number out text
) is 'Форматирует номер телефона по образцу';

------------------------------------------------------------------------------------------------------------------------

create or replace function phone_format_record(
    in_country_code int,
    in_area_code text,
    in_local_number text,

    country_code_example text,
    area_code_example text,
    local_number_example text,

    country_code out text,
    area_code out text,
    local_number out text
)
    returns record
    stable
    --returns null on null input
    parallel safe
    language sql
as
$$;
    select t.*
    from phone_format_record(in_country_code::text, in_area_code, in_local_number,
                                    country_code_example, area_code_example, local_number_example) as t;
$$;


comment on function phone_format_record(
    in_country_code int,
    in_area_code text,
    in_local_number text,

    country_code_example text,
    area_code_example text,
    local_number_example text,

    country_code out text,
    area_code out text,
    local_number out text
) is 'Форматирует номер телефона по образцу';

------------------------------------------------------------------------------------------------------------------------

create or replace function phone_format_record(
    in_country_code text,
    in_area_code text,
    in_local_number text,

    country_code_example int,
    area_code_example text,
    local_number_example text,

    country_code out int,
    area_code out text,
    local_number out text
)
    returns record
    stable
    --returns null on null input
    parallel safe
    language sql
as
$$;
    select t.country_code::int, t.area_code, t.local_number
    from phone_format_record(in_country_code, in_area_code, in_local_number,
                                    country_code_example::text, area_code_example, local_number_example) as t;
$$;

comment on function phone_format_record(
    in_country_code text,
    in_area_code text,
    in_local_number text,

    country_code_example int,
    area_code_example text,
    local_number_example text,

    country_code out int,
    area_code out text,
    local_number out text
) is 'Форматирует номер телефона по образцу';

------------------------------------------------------------------------------------------------------------------------

--TEST
do $$
begin
    -- int - int
    assert (select t is not distinct from row(null::int, null::text, '9651234567'::text)
            from phone_format_record(7, '965', '1234567',
                                            null::int, null::text, '000000') as t);

    -- int - text
    assert (select t is not distinct from row(null::text, null::text, '9651234567'::text)
            from phone_format_record(7, '965', '1234567',
                                            null::text, null::text, '000000') as t);

    -- text - int
    assert (select t is not distinct from row(null::int, null::text, '9651234567'::text)
            from phone_format_record('7', '965', '1234567',
                                            null::int, null::text, '000000') as t);

    -- text - text
    assert (select t is not distinct from row(''::text, ''::text, '965 1234567'::text)
            from phone_format_record('7', '965', '1234567',
                                            '', '', '000 000') as t);

    assert (select t is not distinct from row('7'::text, ''::text, '965 1234567'::text)
            from phone_format_record('7', '965', '1234567',
                                            '0', '', '000 000') as t);

    assert (select t is not distinct from row('+7'::text, '965'::text, '123-45-67 с 9 до 18'::text)
            from phone_format_record('7', '965', '1234567',
                                            '+0', '000', '000-00-00 с 9 до 18') as t);

    assert (select t is not distinct from row(''::text, '+7965'::text, '1234567'::text)
            from phone_format_record('7', '965', '1234567',
                                            '', '+000', '0000000') as t);

    assert (select t is not distinct from row(''::text, '7(965)'::text, '1234567'::text)
            from phone_format_record('7', '965', '1234567',
                                            '', '0(000)', '0000000') as t);
end;
$$;
