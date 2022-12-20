create or replace function email_parse(
    email text,
    username out text,
    domain out text
)
    -- парсит email, возвращает record из 2-х элементов: username и domain
    -- возвращает null, если email невалиден (минимальная проверка синтаксиса)
    returns record
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
as
$$
    -- https://en.wikipedia.org/wiki/Email_address
    select t[1] as username, t[2] as domain
    from regexp_match(email, '^(.+)@([^@]+)$', '') as t
    where octet_length(email) between 6 and 320
      and position('@' in email) > 1 --speed improves
      and octet_length(t[1]) <= 64 and octet_length(t[2]) <= 255;
$$;

-- TEST
do $$
    begin
        --positive
        assert (select username = '111@222' and domain = 'ya.ru'
                from email_parse('111@222@ya.ru') as t);
        --negative
        assert email_parse('123@') is null;
        assert email_parse('@123') is null;
    end;
$$;
