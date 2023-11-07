create or replace function public.csv_parse(
    data text, -- данные в формате CSV
    delimiter char(1) default ',',  -- задайте символ, разделяющий столбцы в строках файла, возможные вариаты: ';', ',', E'\t' (табуляция)
    header boolean default true -- содержит строку заголовка с именами столбцов?
) returns setof text[]
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    language plpgsql
    set search_path = ''
    cost 10
as
$func$
    -- https://en.wikipedia.org/wiki/comma-separated_values
-- https://postgrespro.ru/docs/postgresql/13/sql-copy
declare
    parse_pattern text default replace($$
                     (?: ([^"<delimiter>\r\n]*)         #1 value without quotes or
                       | \x20* ("(?:[^"]+|"")*") \x20*  #2 value inside quotes
                     )
                     (?: (<delimiter>)                  #3 values delimiter or
                       | [\r\n]+                        #  rows delimiter
                     )
                   $$, '<delimiter>', replace(delimiter, E'\t', '\t'));
begin
    return query
    select * 
    from (
        select
            (select array_agg(
                case when length(field) > 1 and
                          left(field, 1) = '"' and
                          right(field, 1) = '"' then replace(substring(field, 2, length(field) - 2), '""', '"')
                     else nullif(trim(field), '')
                end
                order by num)
             from unnest(string_to_array(t.row, E'\x01' || delimiter ||  E'\x02')) with ordinality as q(field, num)
            ) as row
        from unnest(string_to_array(
                 regexp_replace(data || E'\n', parse_pattern, E'\\1\\2\x01\\3\x02', 'gx'),
                 E'\x01\x02'
             )) as t(row)
    ) as t
    where row is not null and array_to_string(row, '') != ''
    offset header::int;
end;
$func$;

comment on function public.csv_parse(data text, delimiter char(1), header boolean) is $$
    Parse CSV strings with PostgreSQL.
    PostgreSQL умеет читать и писать CSV в файл на сервере БД. А это парсер CSV (по спецификации) из строки.
$$;