
create or replace function email_parse(email text)
    -- парсит email, возвращает record из 2-х элементов
    -- возвращает null, если строка не является email (минимальная проверка синтаксиса)
    returns table (username text, domain text)
    stable
    returns null on null input
    parallel safe
    language sql
as
$$
    select t[1] as username,
           t[2] as domain
    from regexp_match(email, '^(.+)@([^@]+)$', '') as t
$$;

-- TEST
select * from email_parse('111@222@ya.ru');
select (email_parse('111@222@ya.ru')).domain;
