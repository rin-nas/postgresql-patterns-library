create or replace function public.json_unicode_unescape(json)
    returns json
    immutable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
return
    $1::jsonb::json;

comment on function public.json_unicode_unescape(json) is $$
    Evaluate escaped Unicode characters in the argument.
    Unicode characters can be specified as \uXXXX (4 hexadecimal digits).
    Hint: convert json column to jsonb.
$$;

--TEST
do $$
begin
    assert public.json_unicode_unescape('"''\u017D\u010F\u00E1r, \\Нello\r\n\t \u270C, Привет! \ud83d\udc18\ud83d\ude03"'::json)::text = '"''Žďár, \\Нello\r\n\t ✌, Привет! 🐘😃"';
end;
$$;
