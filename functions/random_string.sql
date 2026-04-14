create or replace function public.random_string(
    len integer,
    chars varchar(255) default 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
)
    -- возвращает случайно сгенерируемый набор символов необходимой длины из заданного алфавита
    returns text
    volatile
    parallel safe
    returns null on null input
    security invoker
    language sql
    set search_path=''
begin atomic
    select array_to_string(array(
        select substr(chars,((random()*(length(chars)-1)+1)::integer),1)
        from generate_series(1, len)
    ), '');
end;

-- TEST
select public.random_string(10);
