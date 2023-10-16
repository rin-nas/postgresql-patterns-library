create or replace function int_to_binary(n int)
    returns text
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language sql
    set search_path = ''
AS $func$
    select greatest(regexp_replace(n::bit(32)::text, '^0+', ''), '0');
$func$;

comment on function int_to_binary(n int) is $$
    Convert from an integer into a binary representation (for debug purpose).
    Example:
    0 => 0
    1 => 1
    2 => 10
    3 => 11
    4 => 100
    5 => 101
    6 => 110
    7 => 111
    ...
$$;

--TEST

do $do$
begin
   assert (
        with recursive r (n, b) as (
            select 0,     int_to_binary(0)
            union
            select n + 1, int_to_binary(n + 1)
            from r
            where n < 255
        )
        select sum(n) = 32640 and length(string_agg(b, '')) = 1794
        from r
   );
end;
$do$;
