CREATE OR REPLACE FUNCTION public.random_string(
    len integer,
    chars varchar(255) default 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
)
    -- возвращает случайно сгенерируемый набор символов необходимой длины из заданного алфавита
    returns text
    language sql
    volatile
    parallel safe
    returns null on null input
    security invoker
    set search_path=''
AS $$
    SELECT array_to_string(array(
        select substr(chars,((random()*(length(chars)-1)+1)::integer),1)
        from generate_series(1, len)
    ), '');
$$;

-- TEST
select public.random_string(10);
