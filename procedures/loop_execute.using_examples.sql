--деперсонализация (обезличивание) персональных данных (email)
call loop_execute(
    'person_email',
    $$
        WITH s (id, value) AS (
            SELECT id,
                   hash_email_username(email, id)
            FROM person_email
            WHERE id > $1
              AND use_parallel(id, 1, 1)
              AND email IS NOT NULL AND TRIM(email) != ''
              AND NOT is_email_ignore(email)
            ORDER BY id
            LIMIT $2 OFFSET $3
        ),
        m (id) AS (
            UPDATE person_email AS u
            SET email = s.value
            FROM s
            WHERE s.id = u.id
            RETURNING u.id
        )
        SELECT MAX(id)  AS next_start_id,
               COUNT(*) AS affected_rows
        FROM m;
    $$,
    100,  --batch_rows
    1,    --time_max
    true, --is_rollback (for test)
    10    --cycles_max (for test)
);

------------------------------------------------------------------------------------------------------------------------
-- удаление невалидных email
call loop_execute(
    'person_email',
    $$
        WITH s AS (
            SELECT id
            FROM person_email
            WHERE id > $1
              AND use_parallel(id, 1, 1)
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
            DELETE FROM person_email AS d
            WHERE id IN (SELECT id FROM s)
            RETURNING d.id
        )
        SELECT MAX(id)  AS next_start_id,
               COUNT(*) AS affected_rows
        FROM m;
    $$
);
