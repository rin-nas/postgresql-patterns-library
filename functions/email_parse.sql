
create or replace function depers.email_parse(email text)
    -- парсит email, возвращает record из 2-х элементов: username и domain
    -- возвращает null, если email невалиден (минимальная проверка синтаксиса)
    returns table (username text, domain text)
    stable
    returns null on null input
    parallel safe
    language plpgsql
as
$$
    declare
        -- https://en.wikipedia.org/wiki/Email_address
        username_max_length smallint default 64;
        domain_max_length smallint default 255;
    begin
        return query
        select case when octet_length(t[1]) > username_max_length then null else t[1] end as username,
               case when octet_length(t[2]) > domain_max_length then null else t[2] end as domain
        from regexp_match(email, '^(.+)@([^@]+)$', '') as t;
    end
$$;


-- TEST
select * from email_parse('111@222@ya.ru');
select (email_parse('111@222@ya.ru')).domain;
