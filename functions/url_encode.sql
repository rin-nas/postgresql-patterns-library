--see also extension https://github.com/okbob/url_encode with C implementation

create or replace function public.url_encode(text)
    returns text
    immutable
    strict -- returns null if any parameter is null
    language sql
    set search_path = ''
as $$
select
    string_agg(
            case
                when octet_length(s.char) > 1 or s.char !~ '[0-9a-zA-Z:/@._?#-]+'
                then regexp_replace(upper(substring(s.char::bytea::text, 3)), '(..)', E'%\\1', 'g')
                else s.char
            end,
            ''
        )
from unnest(string_to_array($1, null)) as s(char);
$$;

--TEST
do $$
    begin
        assert public.url_encode('hello, привет!') = 'hello%2C%20%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%21';
    end;
$$;
