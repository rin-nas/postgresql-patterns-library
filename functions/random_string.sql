CREATE OR REPLACE FUNCTION depers.random_string(
    len integer,
    chars varchar(255) default 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
)
    -- возвращает случайно сгенерируемый набор символов необходимой длины из заданного алфавита
    RETURNS text
    LANGUAGE SQL
    VOLATILE
    parallel safe
    RETURNS NULL ON NULL INPUT
    SECURITY INVOKER
    SET search_path=''
AS $$
    SELECT array_to_string(array(
        select substr(chars,((random()*(length(chars)-1)+1)::integer),1)
        from generate_series(1, len)
    ), '');
$$;

-- TEST
select random_string(10);
