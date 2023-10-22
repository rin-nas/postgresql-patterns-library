create or replace function public.string_to_codepoints(s text)
    returns int[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $func$
    select array(
        select ascii(t.c)
        from regexp_split_to_table(string_to_codepoints.s, '') as t(c)
        where t.c != ''
    );
$func$;

comment on function public.string_to_codepoints(s text) is 'Converts each string character to unicode codepoints';

--TEST
do $$
  begin
    assert public.string_to_codepoints('') = '{}';
    assert public.string_to_codepoints('Elephant — это слон! 🐘😃')
           = '{69,108,101,112,104,97,110,116,32,8212,32,1101,1090,1086,32,1089,1083,1086,1085,33,32,128024,128515}';
  end;
$$;
