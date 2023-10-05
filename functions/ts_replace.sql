create or replace function public.ts_replace(
    vector tsvector,
    str_from text,
    str_to text
)
    returns tsvector
    stable
    returns null on null input
    parallel safe
    language sql
    set search_path = ''
    cost 1
as
$function$
    with s as (
        select case when lexeme = str_from then str_to
                    else lexeme
               end as new_lexeme,
               unnest(positions) as position,
               unnest(weights) as weight
        from unnest(vector) as t(lexeme, positions, weights)
    )
    --https://www.postgrespro.ru/docs/postgresql/12/datatype-textsearch#DATATYPE-TSVECTOR
    select array_to_string(array(
        select concat(
                      concat($$'$$,
                             replace(replace(new_lexeme, $$'$$, $$''$$), $$\$$, $$\\$$),
                             $$'$$),
                      ':',
                      string_agg(concat(position, weight), ',')
                   )
        from s
        group by new_lexeme
    ), ' ')::tsvector;
$function$;

comment on function public.ts_replace(vector tsvector, str_from text, str_to text) is 'Заменяет заданную лексему в векторе';

--TEST
DO $do$
    BEGIN
        --positive
        assert public.ts_replace($$'test':9,2$$::tsvector, 'test', 'abcd') = $$'abcd':2,9$$::tsvector;
        assert public.ts_replace($$'\\te''st':9,2$$::tsvector, $$\te'st$$, $$\AB'CD$$) = $$'\\AB''CD':2,9$$::tsvector;
        assert public.ts_replace($$'test':9A,2B,13 'база':7D$$::tsvector, 'test', 'база') = $$'база':2B,7,9A,13$$::tsvector;

        --negative
        assert public.ts_replace($$'testing':9,2$$::tsvector, 'test', 'abcd') = $$'testing':2,9$$::tsvector;
        assert public.ts_replace($$'protest':9,2$$::tsvector, 'test', 'abcd') = $$'protest':2,9$$::tsvector;
        assert public.ts_replace($$'test''ing':9A,2B,13 'база':7$$::tsvector, 'test', 'abcd') = $$'test''ing':9A,2B,13 'база':7$$::tsvector;
        assert public.ts_replace($$'protest':9,2$$::tsvector, 'test', null) is null;
    END;
$do$;

------------------------------------------------------------------------------------------------------------------------

create or replace function public.ts_replace(
    vector tsvector,
    arr_from text[],
    arr_to text[]
)
    returns tsvector
    stable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 1
as
$function$
begin
    -- speed improves for empty input arrays
    if cardinality(arr_from) = 0 or
       cardinality(arr_to) = 0
    then
        return vector;
    end if;

    return (
        with s as (
            select coalesce(
                       arr_to[array_position(arr_from, lexeme)],
                       lexeme
                   ) as new_lexeme,
                   unnest(positions) as position,
                   unnest(weights) as weight
            from unnest(vector) as t(lexeme, positions, weights)
        )
        --https://www.postgrespro.ru/docs/postgresql/12/datatype-textsearch#DATATYPE-TSVECTOR
        select array_to_string(array(
            select concat(
                          concat($$'$$,
                                 replace(replace(new_lexeme, $$'$$, $$''$$), $$\$$, $$\\$$),
                                 $$'$$),
                          ':',
                          string_agg(concat(position, weight), ',')
                        )
            from s
            group by new_lexeme
        ), ' ')::tsvector
    );
end;
$function$;

comment on function public.ts_replace(vector tsvector, arr_from text[], arr_to text[]) is 'Заменяет заданные лексемы в векторе';

--TEST
DO $do$
    BEGIN
        --positive
        --replace cat => dog, meow => woof
        assert public.ts_replace(
                   $$'cat':9A,2B,13 'meow':7D$$::tsvector,
                   array['cat', 'meow'],
                   array['dog', 'woof']
               ) = $$'dog':2B,9A,13 'woof':7$$::tsvector;
    END;
$do$;
