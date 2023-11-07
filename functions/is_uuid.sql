create or replace function public.is_uuid(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 5
as
$$
begin
    --https://postgrespro.ru/docs/postgresql/12/datatype-uuid
    if octet_length(str) not between 32 --a0eebc999c0b4ef8bb6d6bb9bd380a11
                                 and 36 --a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11
    then
        return false;
    end if;

    return (
        select s ~ '^[\da-fA-F]{32}$'
               and s ~ '\d'
               and s ~ '[a-fA-F]'
        from replace(str, '-', '') as t(s)
    );
end
$$;

comment on function public.is_uuid(text) is 'Проверяет, что переданная строка является UUID';

--TEST

DO $$
BEGIN
    --positive
    assert public.is_uuid('a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11');
    assert public.is_uuid('A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A11');
    assert public.is_uuid('a0eebc999c0b4ef8bb6d6bb9bd380a11');

    --negative
    assert not public.is_uuid('129Z4LOktlhkcG1hURE6Cc5chbSMYl5C');
    assert not public.is_uuid('A0EEBC99-9C0B-4EF8-BB6D-6BB9BD380A-11');

END $$;

