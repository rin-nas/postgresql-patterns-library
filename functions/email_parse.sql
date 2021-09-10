
create or replace function depers.email_parse(email text)
    returns table (username text, domain text)
    stable
    returns null on null input
    parallel safe
    language sql
as
$$
    -- парсит email, возвращает массив из 2-х элементов, в первом имя пользователя, а во втором домен
    -- возвращает null, если строка не является email (минимальная проверка синтаксиса)
    select t[1] as username,
           t[2] as domain
    from regexp_match(email, '^(.+)@([^@]+)$', '') as t
$$;

-- TEST
select * from depers.email_parse('111@222@ya.ru');
select (depers.email_parse('111@222@ya.ru')).domain;
