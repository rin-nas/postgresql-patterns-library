-- удаление невалидных email
call loop_execute(
    'public.person_email', --table_name
    $query$
        /*
        MATERIALIZED позволяет сначала вычислить все тяжёлые вычисления, а потом модифицировать строки.
        В этом случае длительность блокирования строк будет меньше, это видно в плане запроса.
        */
        WITH s AS MATERIALIZED (
            SELECT id
            FROM public.person_email
            WHERE id > $1
              --AND use_parallel(id, 1, 1)
              AND email IS NOT NULL -- skip NULL
              AND email !~ '^\s*$'  --skip empty (similar NULL)
              AND NOT(
                    AND octet_length(email) BETWEEN 6 AND 320 -- https://en.wikipedia.org/wiki/Email_address
                    AND email LIKE '_%@_%.__%'                -- rough, but quick check email syntax
                    AND is_email(email)                       -- accurate, but slow check email syntax
                  )
            ORDER BY id
            LIMIT $2 OFFSET $3
        ),
        m AS (
            DELETE FROM public.person_email AS d
            WHERE id IN (SELECT id FROM s)
        )
        SELECT MAX(id)  AS stop_id,
               COUNT(*) AS affected_rows
        FROM s;
    $query$
);
