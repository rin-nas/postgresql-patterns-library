-- drop function public.typos_correct(text, interval, boolean);

CREATE OR REPLACE FUNCTION public.typos_correct(
    words    text,
    timeout  interval,
    is_debug bool default false
)
    RETURNS TABLE(
        word_num      bigint,
        word_from     text,
        is_mistake    bool,
        can_correct   bool,
        words_to      jsonb,
        words_details json
    )
    PARALLEL SAFE
    ROWS 10
    STABLE
    RETURNS NULL ON NULL INPUT
    LANGUAGE SQL
    set search_path = ''
AS $BODY$
/*
Описание параметров на входе:
    words     Список слов, где разделителем является перенос строки \n.
              Первые 2 строки -- исходная фраза и фраза в другой раскладке клавиатуры.
              Остальные строки содержат по одному слову в исходной и другой раскладке клавиатуры.
    timeout   Максимальное время выполнения, при превышении которого обработка слов прерывается.
              В этом случае для некоторых слов из списка опечатки могут не исправиться.
    is_debug  Режим отладки, при котором возвращается доп. инфа в поле words_details.

Описание колонок таблицы на выходе:
    word_num        Порядковый номер слова из запроса
    word_from       Исходное слово/фраза
    is_mistake      Исходное слово содержит опечатку (не найдено в словарях)?
    can_correct     Можно исправить опечатку?
    words_to        Исправленные слова без опечатки
                    При однозначном исправлении всегда одно слово, иначе несколько
    words_details   Доп. информация в режиме отладки (если входящий параметр is_debug=true)
*/
-- EXPLAIN
WITH
    vars AS (
        -- 0.21 -- это минимум, чтобы исправить "вадитль" на "водитель"
        -- 0.15 -- это минимум, чтобы исправить "уёетчк" на "учетчик" (меньше уже нельзя, а то запрос работает медленно)
        SELECT set_config('pg_trgm.word_similarity_threshold', 0.15::text, TRUE)::real AS word_similarity_threshold,
               set_config('pg_trgm.similarity_threshold', 0.15::text, TRUE)::real AS similarity_threshold,
               string_to_array(words, E'\n')::text[] AS words_from,
               2 AS ins_cost,
               2 AS del_cost,
               1 AS sub_cost
    ),
    words AS (
        SELECT
            lower(q.word_from) AS word_from,
            q.word_num - 1 AS word_num,
            -- есть слово в словаре русского языка?
            NOT EXISTS(
                SELECT 
                FROM public.wordforms AS dict
                WHERE lower(dict.word) = lower(q.word_from)
                  AND checked = TRUE
            )
            /*
            -- есть слово в названиях профессий?
            AND NOT EXISTS(
                SELECT 
                FROM custom_query_group_name AS dict
                --WHERE lower(q.word_from) = lower(dict.name)
                WHERE lower(q.word_from) = ANY(string_to_array(lower(dict.name), ' ')) --Теперь корректор сравнивает каждое слово запроса с каждым словом из name (профессии). Сравнение именно по словам, иначе "программист net" и "bim менеджер" снова станут "программист туе" и "ишь менеджер".
            )
            */
            AS is_mistake
        FROM unnest((SELECT words_from FROM vars)) WITH ORDINALITY AS q(word_from, word_num)
    )
    -- SELECT * FROM words_from; -- для отладки
    , result AS (
        SELECT *,
           to_jsonb(ARRAY((
               WITH t AS (
                   SELECT *,
                          round(extract(seconds FROM clock_timestamp() - now())::numeric, 4) AS execution_time,
                          ROW_NUMBER() OVER w AS position,
                          levenshtein_rank3 - LEAD(levenshtein_rank3) OVER w AS next_levenshtein_rank3_delta
                   FROM (
                            -- нельзя выносить подзапрос в WITH name AS (SELECT ...),
                            -- т.к. план запроса меняется, итоговый запрос выполняется в 2 раза медленнее (в PostgreSQL 10?)!
                            SELECT q.word_num,
                                   q.word_from,
                                   t.word AS word_to,
                                   round(word_similarity(q.word_from, t.word)::numeric, 4) AS word_similarity_rank,
                                   round(similarity(q.word_from, t.word)::numeric, 4)      AS similarity_rank,
                                   levenshtein(q.word_from, t.word)                                             AS levenshtein_distance1,
                                   levenshtein(q.word_from, t.word, vars.ins_cost, vars.del_cost,vars.sub_cost) AS levenshtein_distance2,
                                   round(sqrt(levenshtein(q.word_from, t.word) *
                                              levenshtein(q.word_from, t.word, vars.ins_cost, vars.del_cost, vars.sub_cost))::numeric, 4) AS levenshtein_distance3, -- среднее геометрическое
                                   round((1 - sqrt(levenshtein(q.word_from, t.word) *
                                                   levenshtein(q.word_from, t.word, vars.ins_cost, vars.del_cost, vars.sub_cost)) / length(t.word))::numeric, 4) AS levenshtein_rank3
                            FROM public.wordforms AS t, vars
                            WHERE lower(t.word) % q.word_from -- используем GIN индекс!
                        ) AS t
                   WHERE TRUE
                     AND levenshtein_distance1 < 5 AND levenshtein_rank3 > 0.55
                       WINDOW w AS (ORDER BY levenshtein_distance1,
                           levenshtein_rank3 DESC,
                           word_similarity_rank DESC,
                           similarity_rank DESC)
                   ORDER BY levenshtein_distance1,
                            levenshtein_rank3 DESC,
                            word_similarity_rank DESC,
                            similarity_rank DESC
                   LIMIT 3
                   --LIMIT 10 -- для отладки
                   )
                   SELECT to_jsonb(tt.*) FROM (
                      SELECT *,
                             -- если у нескольких кандидатов подряд рейтинг отличается незначительно,
                             -- то это не точное исправление (автоисправлять нельзя, только предлагать варианты)
                             position = 1
                                 AND (next_levenshtein_rank3_delta IS NULL OR
                                 -- 0.03 -- это минимум, чтобы исправить "онолитик" на "аналитик"
                                 next_levenshtein_rank3_delta > 0.03) AS can_correct
                      FROM t
                      LIMIT 3
                      --LIMIT 10 -- для отладки
                   ) AS tt
        ))) AS json
    FROM words AS q
    WHERE clock_timestamp() - now() < timeout -- ограничиваем время выполнения запроса!
      AND q.is_mistake = TRUE
      -- первые 2 элемента -- это всегда исходный текст и текст в другой раскладке клавиатуры
      -- если один из этих элементов не является опечаткой, то прерываем цикл
      AND NOT EXISTS(SELECT FROM words AS s WHERE s.word_num < 2)
      -- если все отдельные слова не имеют опечаток, то прерываем цикл
      AND (SELECT COUNT(*) = 2 OR (COUNT(*) - 2) / 2 != COUNT(*) FILTER (WHERE s.word_num >= 2) FROM words AS s)
    ORDER BY word_num
)
SELECT w.word_num,
       w.word_from,
       w.is_mistake,
       COALESCE(r.json->0->>'can_correct' = 'true', FALSE) AS can_correct,
       CASE
           WHEN r.json->0->>'can_correct' = 'true' THEN to_jsonb(ARRAY[r.json->0->>'word_to'])
           ELSE (SELECT jsonb_agg(o->'word_to') FROM jsonb_array_elements(json) AS t(o))
       END AS words_to,
       CASE WHEN is_debug THEN jsonb_pretty(json)::json ELSE NULL END AS words_details
FROM words AS w
LEFT JOIN result AS r ON r.word_num = w.word_num
ORDER BY w.word_num
$BODY$;

-- Тестирование. Если какой-либо запрос не выполнится, то мы увидим текст ошибки.
--EXPLAIN
SELECT * FROM public.typos_correct(E'повар-пивовар\ngjdfh-gbdjdfh\nповар\nпивовар\ngjdfh\ngbdjdfh', '200ms'::interval, true);
SELECT * FROM public.typos_correct(E'бухалтер\n,e[fknth', '200ms'::interval, true);
SELECT * FROM public.typos_correct(E'моляр\nvjkzh', '200ms'::interval, true);
SELECT * FROM public.typos_correct(E'моляр\nvjkzh', '200ms'::interval, false);
SELECT * FROM public.typos_correct(E'моляр\nvjkzh', '200ms'::interval);
