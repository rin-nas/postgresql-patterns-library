
create function email_parse(email text) returns text[]
    PARALLEL SAFE
    LANGUAGE SQL
    STABLE
    RETURNS NULL ON NULL INPUT
as
$BODY$

    -- парсит email, возвращает массив из 2-х элементов, в первом имя пользователя, а во втором домен
    -- возвращает null, если строка не является email (минимальная проверка синтаксиса)
    select regexp_match(email, '^(.+)@([^@]+)$', '');

$BODY$;

-- TEST
select email_parse('my@email@gmail.com.uk'); -- {my@email,gmail.com.uk}
