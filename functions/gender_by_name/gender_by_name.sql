create or replace function depers.gender_by_name(
    full_name text, -- ФИО, где фамилия имя и отчество могут следовать в любом порядке
                    -- или Ф\nИ\nО с переносами строк (порядок следования Ф, И, О важен) улучшит качество разпознавания
    is_strict boolean default false -- для неоднозначных ситуаций не учитывает веса и всегда возвращает unknown
) returns depers.gender
    immutable
    strict -- returns null if any parameter is null
    parallel safe -- Postgres 10 or later
    language sql
    set search_path = ''
as
$func$

with enter_sentence as (
    select lower((regexp_matches(t.phrase,
            $$
                #выделяем слова из текста, отделяем прилипшие друг к другу
                  [A-Z](?:[a-z]+|\.)   #En
                | [А-ЯЁ](?:[а-яё]+|\.) #Ru
                | [A-Z]+    #EN
                | [А-ЯЁ]+   #RU
                | [a-z]+    #en
                | [а-яё]+   #ru
            $$, 'gx'))[1]) as word,
           (array['L', 'F', 'M'])[t.position] as type  -- L - lastname, F - firstname, M - middlename
    from unnest(string_to_array(gender_by_name.full_name, e'\n')) with ordinality t(phrase, position)
    where array_length(regexp_split_to_array(gender_by_name.full_name, '\n\s*'), 1) = 3
)
, enter_sentence2 as (
    select distinct on (es.word) es.*
    from enter_sentence as es
    order by es.word, es.type --дедупликация слов
)
--select * from enter_sentence2; --отладка
, sentence as (
    select lower((regexp_matches(t[1], '[a-zа-яё]+', 'ig'))[1]) as word,
           (array['L', 'F', 'M'])[row_number() over ()] as type -- L - lastname, F - firstname, M - middlename
    from regexp_matches(gender_by_name.full_name,
$$
#выделяем слова из текста, учитываем слова через дефис и в скобках, отделяем прилипшие друг к другу
  [A-Z](?:[a-z]+ (?:-       [A-Z][a-z]+)*
                 (?:\s*\(\s*[A-Z][a-z]+\s*\))*
         |\.
       ) #En
| [А-ЯЁ](?:[а-яё]+ (?:-       [А-ЯЁ][а-яё]+)*
                   (?:\s*\(\s*[А-ЯЁ][а-яё]+\s*\))*
          |\.
        ) #Ru
| [A-Z]+ (?:-       [A-Z]+)*
         (?:\s*\(\s*[A-Z]+\s*\))*    #EN
| [А-ЯЁ]+ (?:-       [А-ЯЁ]+)*
          (?:\s*\(\s*[А-ЯЁ]+\s*\))*  #RU
| [a-z]+ (?:-       [a-z]+)*
         (?:\s*\(\s*[a-z]+\s*\))*    #en
| [а-яё]+ (?:-       [а-яё]+)*
          (?:\s*\(\s*[а-яё]+\s*\))*  #ru
$$, 'gx') as t
)
, sentence2 as (
    select distinct on (s.word) s.*
    from sentence as s
    order by s.word, s.type --дедупликация слов
)
--select * from sentence2; --отладка
, found as (
    -- проверка имён
    select distinct on (s.word)
        d.gender, s.word, 'F' as found_type, es.type as enter_type,
        -- используем популярность имён, чтобы корректно определялся пол для ФИО типа "величко ольга", "ким александр", "герман анна"
        -- по словарю величко - мужское имя, а ольга - женское, но в данном ФИО величко - это фамилия
        -- т.к. имя находится по полному совпадению, то вес имени выше, чем у фамилии и отчества
        1 + coalesce(d.popularity, 0) as weight
    from sentence2 as s
    join depers.person_name_dictionary as d
         on d.gender is not null -- пропускаем неоднозначные имена типа "никита"
         and s.word in (lower(d.name), lower(d.name_translit))
    left join enter_sentence2 as es on es.word = s.word

    union all

    --проверка фамилий
    select distinct on (s.word)
         d.gender, s.word, 'L' as found_type, es.type as enter_type,
         1 as weight
    from sentence2 as s
    join depers.gender_by_ending as d
         on d.gender is not null
         and d.name_type = 'last_name'
         and length(s.word) > length(d.ending)
         and lower(right(s.word, length(d.ending))) in (lower(d.ending), lower(d.ending_translit))
    left join enter_sentence2 as es on es.word = s.word

    union all

    --проверка отчеств
    select distinct on (s.word)
         d.gender, s.word, 'M' as found_type, es.type as enter_type,
         1 as weight
    from sentence2 as s
    join depers.gender_by_ending as d
         on d.gender is not null
         and d.name_type = 'middle_name'
         and lower(right(s.word, length(d.ending))) in (lower(d.ending), lower(d.ending_translit))
    left join enter_sentence2 as es on es.word = s.word
)
--select * from found; -- отладка
, found1 as (
    select distinct on (f.gender, f.word) f.* --e'кызы\nэркин\nайпери' (эркин находится в имени и фамилии мужского пола)
    from found as f
    order by f.gender, f.word, f.weight desc
)
, found2 as (
    -- корректировка весов для e'си-ян-пин\nелена\n' и e'саид\nалина\nакбари'
    select max(f.gender)                                         as gender,
           array_to_string(array_agg(f.word order by f.word), ' ') as word,
           max(f.found_type)                                     as found_type,
           max(f.enter_type)                                     as enter_type,
           sum(f.weight) - count(*) + 1                          as weight
    from found1 as f
    group by f.gender, f.found_type--, enter_type
)
--select * from found2; -- отладка
, stat as (
    --пользователи путают Ф,И,О местами и надеяться только на позицию нельзя!
    select sum((f.gender = 'male')::int * f.weight)
               + (count(distinct f.word) != count(f.word))::int -- решение об увеличении веса на основе позиции
               * sum((f.gender = 'male' and f.found_type = coalesce(f.enter_type, '*'))::int) -- тест: e'холин\nникита\n'
               as male_weight,
           sum((f.gender = 'female')::int * f.weight)
               + (count(distinct f.word) != count(f.word))::int -- решение об увеличении веса на основе позиции
               * sum((f.gender = 'female' and f.found_type = coalesce(f.enter_type, '*'))::int)
               as female_weight
    from found2 as f
    -- игнорируем ФИО разных людей типа 'алексей иванович светлана николаевна' или 'калинина марина сергей иванов'
    where not(select count(distinct f.gender) filter (where f.found_type = 'F') = 2
                     and 2 in (count(distinct f.gender) filter (where f.found_type = 'M'),
                               count(distinct f.gender) filter (where f.found_type = 'L'))
                from found2 as f)
)
--select * from stat; -- отладка
select case when gender_by_name.is_strict and s.male_weight > 0 and s.female_weight > 0 then 'unknown'
           --ФИО от нескольких разных людей не должны определяться
            when s.male_weight > 0 and s.female_weight > 0
                 and gender_by_name.full_name ~* '([,/\\;+]|\m(и|или|семья)\M)|[а-я](ины|[оеё]вы|[цс]кие|[внтлр]ые|[кчн]ие)\M' then 'unknown'
            when s.male_weight - s.female_weight > 0 then 'male'
            when s.male_weight - s.female_weight < 0 then 'female'
            else 'unknown'
       end::depers.gender as gender
from stat as s;

$func$;