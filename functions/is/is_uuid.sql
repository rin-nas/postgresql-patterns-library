create or replace function public.is_uuid(str text)
    returns boolean
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$$
    --https://postgrespro.ru/docs/postgresql/12/datatype-uuid
    select case when octet_length(str) between 32 --a0eebc999c0b4ef8bb6d6bb9bd380a11
                                           and 36 --a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11
                then     str ~ '\d'
                     and str ~ '[a-fA-F]'
                     and replace(str, '-', '') ~ '^[\da-fA-F]{32}$'
                else false
           end;
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
