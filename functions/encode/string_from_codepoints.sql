create or replace function public.string_from_codepoints(a int[])
    returns text
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $func$
    select array_to_string(array(
        select chr(t.code)
        from unnest(string_from_codepoints.a) as t(code)
    ), '');
$func$;

comment on function public.string_from_codepoints(a int[]) is 'Converts unicode codepoints to string';

--TEST
do $$
  begin
    assert public.string_from_codepoints('{}') = '';
    assert public.string_from_codepoints('{69,108,101,112,104,97,110,116,32,8212,32,1101,1090,1086,32,1089,1083,1086,1085,33,32,128024,128515}')
           = 'Elephant — это слон! 🐘😃';
  end;
$$;
