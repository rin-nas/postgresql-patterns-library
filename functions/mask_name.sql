create or replace function public.mask_name(text)
    returns text
    immutable
    returns null on null input
    parallel safe -- postgres 10 or later
    language sql
    set search_path = ''
as $func$
    select rpad(upper(left($1, 1)), char_length($1), '*');
$func$;

comment on function public.mask_name(text) is
    'Маскирует имя пользователя (имя, фамилию, отчество). Оставляет первую букву в верхнем регистре, остальные заменяет на звёздочку';

--TEST
do $$
    begin
        assert public.mask_name('Иванов') = 'И*****';
        assert public.mask_name('иван') = 'И***';

        assert public.mask_name(null) is null;
        assert public.mask_name('') = '';
        assert public.mask_name('И') = 'И';
    end;
$$;
