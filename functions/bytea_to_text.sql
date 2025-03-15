create or replace function public.bytea_to_text(bytea)
    returns text 
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
as $func$ 
    select convert_from($1, current_setting('server_encoding'));
$func$;

comment on function public.bytea_to_text(bytea) is 'Converts bytea to text';

--TEST
do $$
    begin
        assert public.bytea_to_text('Юлия, съешь же ещё этих мягких французских булок из Йошкар-Олы, да выпей алтайского чаю.'::bytea) = 'Юлия, съешь же ещё этих мягких французских булок из Йошкар-Олы, да выпей алтайского чаю.';
    end;
$$;

