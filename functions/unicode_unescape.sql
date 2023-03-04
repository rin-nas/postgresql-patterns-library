create or replace function unicode_unescape(text)
    returns text
    immutable
    returns null on null input
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
as
$func$
BEGIN
    if current_setting('server_version_num') < '140000' then
        return unistr($1);
    else
        $1 := replace($1, $$'$$, $$''$$);
        EXECUTE 'SELECT E''' || $1 || '''' INTO $1;
        return $1;
    end if;
END
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
