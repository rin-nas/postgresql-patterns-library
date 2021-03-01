create or replace function csv_parse(
    data text, -- данные в формате CSV без header
    delimiter char(1) default ',',  -- задайте символ, разделяющий столбцы в строках файла, возможные вариаты: ';', ',', E'\t' (табуляция)
    header boolean default true -- содержит строку заголовка с именами столбцов, игнорировать её?
) returns setof text[]
    immutable
    strict
    parallel safe -- Postgres 10 or later
    language plpgsql
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
    select * from (
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

-- TEST
select
    CASE WHEN row[1] ~ '^\d+$' THEN row[1]::integer ELSE NULL END AS id,
    row[2] AS kladr_id,
    row[3] AS name
from csv_parse($$
id; kladr_id; name
501 ; 8300000000000 ; ";Автономный ;"";округ""
  ""Ненецкий"";";unknown
      751;8600800000000; "  Автономный округ ""Ханты-Мансийский"", Район Советский" ;
     1755;8700300000000;  Автономный округ Чукотский, Район Билибинский
     1725;7501900000000;Край Забайкальский, Район Петровск-Забайкальский

  ;;
       711;2302100000000;Край Краснодарский, Район Лабинский
       729;2401600000000;Край Красноярский, Район Иланский
       765;2700700000000;Край Хабаровский, Район Вяземский
       765;;
$$, ';', false) as row;
