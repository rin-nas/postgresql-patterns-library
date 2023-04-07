# `loop_execute()` — safe modify millions rows in table

English:

Update or delete rows incrementally in batches with multiple separate transactions.
This maximizes your table availability since you only need to keep locks for a short period of time. Also allows dead rows to be reused.
There is a progress of execution in percent and a prediction of the end work time!

Russian:

Процедура для обработки строк в больших таблицах (тысячи и миллионы строк) с контролируемым временем блокировки строк на запись.
Принцип работы — выполняет в цикле CTE DML запрос, который добавляет, обновляет или удаляет записи в таблице.
В завершении каждого цикла изменения фиксируются (либо откатываются для целей тестирования, это настраивается).
Автоматически адаптируется под нагрузку на БД. На реплику данные передаются постепенно небольшими порциями, а не одним огромным куском.
В процессе обработки показывает в psql консоли:
   * количество модифицированных и обработанных записей в таблице
   * сколько времени прошло, сколько примерно времени осталось до завершения, прогресс выполнения в процентах

Прогресс выполнения в процентах для работающего процесса отображается ещё в колонке pg_stat_activity.application_name!
Процедура не предназначена для выполнения в транзакции, т.к. сама делает много маленьких транзакций.
