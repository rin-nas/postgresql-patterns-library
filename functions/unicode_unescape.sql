create or replace function unicode_unescape(text)
    returns text
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$func$
    select right(left(('"' || $1 || '"')::jsonb::text, -1), -1);
$func$;

comment on function unicode_unescape(text) is $$
    Evaluate escaped Unicode characters in the argument.
    Unicode characters should be specified as \uXXXX (4 hexadecimal digits).
$$;

--TEST
do $$
  begin
    assert unicode_unescape('\u017D\u010F\u00E1r') = 'Žďár';
    assert unicode_unescape('\u043f\u0440\u0438\u0432\u0435\u0442') = 'привет';
    assert unicode_unescape('\ud83d\udc18\ud83d\ude03') = '🐘😃';
  end;
$$;
