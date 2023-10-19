create or replace function public.bin(n int)
    returns text
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    security invoker
    language plpgsql
    set search_path = ''
AS $func$
declare
    s text := '';
    prefix text := case when n < 0 then '-' else '' end;
begin
    -- select greatest(regexp_replace(n::bit(32)::text, '^0+', ''), '0'); -- old deprecated
    n = abs(n);
    loop
        s := (n % 2)::text || s;
        n := n / 2;
        exit when n = 0;
    end loop;
    return prefix || s;
end;
$func$;

comment on function public.bin(n int) is $$
    Convert from an integer into a bin representation (for debug purpose).
    Example:
    ...
    -3 => -11
    -2 => -10
    -1 => -1
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
            select -8,    public.bin(-8)
            union
            select n + 1, public.bin(n + 1)
            from r
            where n < 255
        )
        select (count(n), sum(n), length(string_agg(b, ''))) = (264, 32604, 1823)
        from r
   );
end;
$do$;
