--деперсонализация (обезличивание) email
call loop_execute(
    'person_email',
    $$
        WITH s (id, value) AS (
            SELECT id,
                   hash_email_username(email, id)
            FROM person_email
            WHERE id > $1
              AND use_parallel(id, 1, 1) --https://github.com/rin-nas/postgresql-patterns-library/blob/master/functions/use_parallel.sql
              AND email IS NOT NULL AND TRIM(email) != ''
              AND NOT is_email_ignore(email)
            ORDER BY id
            LIMIT $2
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

-- удаление невалидных email
call loop_execute(
    'person_email',
    $$
        WITH s AS (
            SELECT id
            FROM person_email
            WHERE id > $1
              AND use_parallel(id, 1, 1) --https://github.com/rin-nas/postgresql-patterns-library/blob/master/functions/use_parallel.sql
              AND email IS NOT NULL AND TRIM(email) != ''
              AND NOT(
                    octet_length(email) BETWEEN 6 AND 320
                    AND email = trim(email)
                    AND email LIKE '_%@_%.__%'
                    AND is_email(email)
                )
            ORDER BY id
            LIMIT $2
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
