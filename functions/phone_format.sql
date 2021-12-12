create or replace function phone_format(
    phone text, --E.164, можно без первого символа "+" (остаются только цифры)
    phone_example text default '+12223334455', --номер телефона в любом формате
    check_digits_count bool default false -- проверять, чтобы кол-во цифр в phone и phone_example было одинаковое
)
    returns text
    stable
    returns null on null input
    parallel safe
    language plpgsql
as
$$
declare
    part_regexp constant text[] not null default array['^\d+', '^[\+ ()\-./]+', '^\D+'];
    index_regexp int not null default 0;
    phone_out text not null default '';
    m text[];
    i int not null default 0;
    len int not null default 0;
    phone_digits_count int not null default 0;
    phone_example_digits_count int not null default 0;
begin

    if phone = '' then
        return '';
    end if;

    if phone !~ '^\+?\d+$' then
        raise exception 'In 1-st parameter value expected in this format: E.164 or digits or empty, but ''%'' given', phone;
    end if;

    phone         := ltrim(phone, '+');
    phone_example := trim(phone_example);

    if check_digits_count then
        phone_digits_count         := octet_length(phone);
        phone_example_digits_count := octet_length(regexp_replace(phone_example, '\D+', '', 'g'));
        if phone_digits_count != phone_example_digits_count then
            raise exception 'In 2-nd parameter value % digits expected, but % given', phone_digits_count, phone_example_digits_count
                 using hint = format('1-st parameter value has %s digits', phone_digits_count);
        end if;
    end if;

    loop
        i := i + 1;
        exit when phone = '' or phone_example = ''
                  or i > 100; --защита от зацикливания, если что-то пойдёт не так
        index_regexp := i % 2 + 1 + (i = 1)::int;
        m := regexp_match(phone_example, part_regexp[index_regexp]);
        if m is null then
            continue when i = 1;
            exit when i > 1;
        end if;

        len := length(m[1]);
        phone_example := right(phone_example, -1 * len);
        if index_regexp = 1 then
            phone_out := phone_out || left(phone, len);
            phone := right(phone, -1 * len);
        else
            phone_out := phone_out || m[1];
        end if;

    end loop;

    return trim(regexp_replace(phone_out || phone || phone_example, '  +', ' ', 'g'));
end
$$;

comment on function phone_format(
    phone text,
    phone_example text,
    check_digits_count bool
) is 'Форматирует номер телефона по образцу';

--TEST
do $$
    begin
        --positive
        assert phone_format('79651234567') = '+79651234567';
        assert phone_format('', '000') = '';
        assert phone_format('1', '000') = '1';

        assert phone_format('+79651234567', ' 00000000000 ') = '79651234567';
        assert phone_format('79651234567', '0  0000000000') = '7 9651234567';
        assert phone_format('79651234567', '0 0') = '7 9651234567';
        assert phone_format('79651234567', '00 0') = '79 651234567';
        assert phone_format('79651234567', '000 0') = '796 51234567';
        assert phone_format('79651234567', '+0 (000) 0000000') = '+7 (965) 1234567';
        assert phone_format('79651234567', 'моб. +0 000 000-00-00 доп 123') = 'моб. +7 965 123-45-67 доп 123';

        assert phone_format('21079651234567', '210 0000 0000000', true) = '210 7965 1234567';

        --negative
        assert phone_format(null) is null;
    end;
$$;
