create or replace function urlencode(text)
    returns text
    language sql
    immutable
    strict
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
from (
         select char
         --from regexp_split_to_table($1, '') as ch
         from unnest(string_to_array($1, null)) as char
     ) as s;
$$;

--TEST
do $$
    begin
        assert urlencode('hello, привет!') = 'hello%2C%20%D0%BF%D1%80%D0%B8%D0%B2%D0%B5%D1%82%21';
    end;
$$;
