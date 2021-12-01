create or replace function phone_format(
    phone text, --только цифры, не пусто
    phone_example text default '+12223334455' --E.164
)
    returns text
    stable
    returns null on null input
    parallel safe
    language plpgsql
as
$$
declare
    part_regexp constant text[] default array['^\d+', '^\D+'];
    index_regexp int;
    phone_out text default '';
    m text[];
    i int default 0;
    len int;
begin

    if phone = '' then
        return '';
    end if;

    if phone !~ '^\d+$' then
        raise exception 'In 1-st patameter value empty or digits expected, but ''%'' given', phone;
    end if;

    phone_example := trim(phone_example);

    loop
        i := i + 1;
        exit when phone = '' or phone_example = ''
                  or i > 100; --защита от зацикливания, если что-то пойдёт не так
        index_regexp := i % 2 + 1;
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
    phone_example text
) is 'Форматирует номер телефона по образцу';

--TEST
do $$
    begin
        --positive
        assert phone_format('79651234567') = '+79651234567';
        assert phone_format('', '000') = '';
        assert phone_format('1', '000') = '1';
        assert phone_format('79651234567', ' 00000000000 ') = '79651234567';
        assert phone_format('79651234567', '0  0000000000') = '7 9651234567';
        assert phone_format('79651234567', '0 0') = '7 9651234567';
        assert phone_format('79651234567', '00 0') = '79 651234567';
        assert phone_format('79651234567', '000 0') = '796 51234567';
        assert phone_format('79651234567', '+0 (000) 0000000') = '+7 (965) 1234567';
        assert phone_format('79651234567', '+0 000 000-00-00 доп 123') = '+7 965 123-45-67 доп 123';

        --negative
        assert phone_format(null) is null;
    end;
$$;
