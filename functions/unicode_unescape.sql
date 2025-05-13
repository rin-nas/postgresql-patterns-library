create or replace function public.unicode_unescape(text)
    returns text
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$func$
    -- input string - only as \uXXXX sequence
    -- TODO validate format and return NULL for invalid strings (see string_to_jsonb.sql)?
    select concat('"', $1, '"')::jsonb->>0;
$func$;

comment on function public.unicode_unescape(text) is $$
    Evaluate escaped Unicode characters in the argument.
    Unicode characters should be specified as \uXXXX (4 hexadecimal digits).
$$;

--TEST
do $$
  begin
    assert public.unicode_unescape('\u017D\u010F\u00E1r') = 'Žďár';
    assert public.unicode_unescape('\u043f\u0440\u0438\u0432\u0435\u0442') = 'привет';
    assert public.unicode_unescape('\ud83d\udc18\ud83d\ude03') = '🐘😃';
  end;
$$;
