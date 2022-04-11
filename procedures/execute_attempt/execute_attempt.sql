-- Inspired by https://postgres.ai/blog/20210923-zero-downtime-postgres-schema-migrations-lock-timeout-and-retries

-- See detail documentation below!

create or replace procedure execute_attempt(
    --required params:
    query text,
    --optional params:
    lock_timeout text default '100ms',
    max_attempts int default 50
)
    language plpgsql
as
$procedure$
declare
    lock_timeout_old constant text not null default current_setting('lock_timeout');
    time_start constant timestamp not null default clock_timestamp();
    time_elapsed numeric not null default 0; -- длительность выполнения всех запросов, в секундах
    delay numeric not null default 0;
begin
    perform set_config('lock_timeout', lock_timeout, true);

    for cur_attempt in 1..max_attempts loop
        begin
            execute query;
            perform set_config('lock_timeout', lock_timeout_old, true);
            exit;
        exception when lock_not_available then
            if cur_attempt < max_attempts then
                time_elapsed := round(extract('epoch' from clock_timestamp() - time_start)::numeric, 2);
                delay := round(greatest(sqrt(time_elapsed * 1), 1), 2);
                delay := round(((random() * (delay - 1)) + 1)::numeric, 2);
                raise warning
                    'Attempt % of % to execute query failed due lock timeout %, next replay after % second',
                    cur_attempt, max_attempts, lock_timeout, delay;
                perform pg_sleep(delay);
            else
                perform set_config('lock_timeout', lock_timeout_old, true);
                raise warning
                    'Attempt % of % to execute query failed due lock timeout %',
                    cur_attempt, max_attempts, lock_timeout;
                raise; -- raise the original exception
            end if;
        end;
    end loop;

end
$procedure$;

comment on procedure execute_attempt(
    --required params:
    query text, --один или несколько запросов через точку с запятой, которые выполняются в подтранзакции
    --optional params:
    lock_timeout text, -- Сколько времени ждать получения блокировки объекта БД (например, таблицы).
                       -- После получения блокировки SQL команда её держит и не отпускает до завершения работы!
    max_attempts int --Максимальное количество попыток выполнения
) is $$
    Процедура предназначена для безопасного выполнения одного или нескольких DDL запросов в БД. Например, миграций БД.
    Пытается выполнить запросы в query с учётом ограничения lock_timeout и максимальным количествоим попыток max_attempts раз.
    В случае неудачи все выполненные запросы в query откатывает и повторяет попытку выполнения всех запросов из query.
    Перед каждой попыткой выполнения есть задержка, которая постепенно увеличивается.
    
    Следует учесть, что в одной транзакции нельзя вызывать эту процедуру несколько раз подряд.
    Иначе могут возникнуть проблемы с долгим удержанием блокировок над объектами БД. 
    В этом случае параллельные запросы могут обращаться к заблокированным объектам БД и выстроятся в очередь.
    В одной транзакции д.б. вызов только этой процедуры, только 1 раз, никаких других SQL запросов до или после.
    Все SQL команды с миграцией будут выполняться из этой процедуры.
    Т.о. эта процедура больше подходит для автоматизации ручных миграций БД, а не автоматических.
    
$$;

/*
Пример неправильного использования процедуры.
Выполнил для большой таблицы call execute_attempt('alter table tbl alter column id type bigint using id::bigint');
После этого INSERT запросы в эту таблицу выстроились в очередь. Пришлось alter table отменить.
Изменение типа колонки нужно делать через добавление новой колонки, её заполнения значениями через UPDATE и INSERT триггерами, удаления старой колонки и переименования новой в старую.
*/
