--деперсонализация (обезличивание) email
call loop_execute(
    'person_email',
    $$
        WITH s AS (
            SELECT id,
                   depers.hash_email_username(email, id) AS email
            FROM person_email
            WHERE id > $1
              AND use_cpu(id, 1, 4)
              AND email IS NOT NULL AND TRIM(email) != ''
              AND NOT depers.is_email_ignore(email)
            ORDER BY id
            LIMIT $2
        ),
        m AS (
            UPDATE person_email AS u
            SET email = s.email
            FROM s
            WHERE s.id = u.id
            RETURNING u.id
        )
        SELECT MAX(id)  AS next_start_id,
               COUNT(*) AS affected_rows
        FROM m;
    $$
);

-- удаление невалидных email
call loop_execute(
    'person_email',
    $$
        WITH s AS (
            SELECT id
            FROM person_email
            WHERE id > $1
              AND use_cpu(id, 1, 4)
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
