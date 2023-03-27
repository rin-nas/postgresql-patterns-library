# TODO

1. Добавить автотесты
2. https://github.com/theory/pgtap/blob/master/tools/parallel_conn.sh
3. Добавить задавать свой SQL запрос для вычисления кол-ва записей для обработки (total). Пример:
   ```sql
   call loop_execute(
        'v3_resume_autoresponse_log',
        $$
        WITH s AS MATERIALIZED (
            SELECT id
            FROM v3_resume_autoresponse_log
            WHERE id>$1 AND created_at < CURRENT_DATE-INTERVAL '2 weeks'
            ORDER BY id
            LIMIT $2 OFFSET $3
        ),
        m AS (
            DELETE FROM v3_resume_autoresponse_log AS d
            WHERE id IN (SELECT id FROM s)
        )
        SELECT MAX(id)  AS stop_id,
               COUNT(*) AS affected_rows
        FROM s;
    $$
    );
    ```
