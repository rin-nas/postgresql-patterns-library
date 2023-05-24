--деперсонализация (обезличивание) персональных данных (email)
call loop_execute(
    'public.person_email', --table_name
    $query$
        /*
        MATERIALIZED позволяет сначала вычислить все тяжёлые вычисления, а потом модифицировать строки.
        В этом случае длительность блокирования строк будет меньше, это видно в плане запроса.
        */
        WITH s (id, value) AS MATERIALIZED (
            SELECT id,
                   hash_email_username(email, id)
            FROM public.person_email
            WHERE id > $1
              --AND use_parallel(id, 1, 1)
              AND email IS NOT NULL AND TRIM(email) != ''
              AND NOT is_email_ignore(email)
            ORDER BY id
            LIMIT $2 OFFSET $3
        ),
        m AS (
            UPDATE public.person_email AS u
            SET email = s.value
            FROM s
            WHERE s.id = u.id
        )
        SELECT MAX(id)  AS stop_id,
               COUNT(*) AS affected_rows
        FROM s;
    $query$
);
