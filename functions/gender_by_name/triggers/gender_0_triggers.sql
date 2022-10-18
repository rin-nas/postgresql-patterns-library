--Дать возможность в триггере для определения пола указывать пол явно

CREATE OR REPLACE FUNCTION trigger_save_update_of() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
BEGIN
    -- для передачи данных между триггерными функциями используем временную таблицу, которая доступна только в транзакции
    CREATE TEMP TABLE IF NOT EXISTS update_of (
        table_oid oid not null,
        column_name text not null,
        id int not null
    ) ON COMMIT DROP;

    INSERT INTO update_of
    SELECT TG_RELID, unnest(TG_ARGV), NEW.id;

    RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION gender_determine() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
DECLARE
    update_of text[] default ARRAY[]::text[]; --массив с названиями колонок, явно указанных в запросе UPDATE
BEGIN

    IF TG_OP = 'UPDATE'
       AND (
           --условие срабатывания триггера {person|resume}__gender_determine_step1:
           OLD.gender IS NOT DISTINCT FROM NEW.gender
           --условие срабатывания триггера {person|resume}__gender_determine_step2:
           OR (OLD.surname, OLD.name, OLD.second_name) IS NOT DISTINCT FROM (NEW.surname, NEW.name, NEW.second_name)
       )
       -- проверяем, что существует временная таблица update_of
       AND EXISTS (
               SELECT
                 FROM information_schema.tables
                WHERE table_schema LIKE 'pg_temp_%'
                  AND table_name = 'update_of'
           )
    THEN
        WITH d AS (
            DELETE FROM update_of AS uo
            WHERE uo.table_oid = TG_RELID AND uo.id = NEW.id
            RETURNING uo.column_name
        )
        SELECT array_agg(column_name) INTO update_of FROM d;
    END IF;

    -- пол не может быть установлен без ФИО
    IF (NEW.name, NEW.surname, NEW.second_name) IS NOT DISTINCT FROM (NULL, NULL, NULL)
    THEN
        NEW.gender = NULL;
        RETURN NEW;
    END IF;

    -- если пол уже изменили явно вручную
    IF NEW.gender IS NOT NULL
       AND (TG_OP = 'INSERT'
            OR NEW.gender IS DISTINCT FROM OLD.gender
            OR 'gender' = ANY(update_of)
           )
    THEN
        RETURN NEW;
    END IF;

    -- если это вставка записи или ФИО изменилось или нужно определить пол автоматически
    IF TG_OP = 'INSERT'
        OR (OLD.gender IS NOT NULL AND NEW.gender IS NULL)
        OR (NEW.name, NEW.surname, NEW.second_name) IS DISTINCT FROM (OLD.name, OLD.surname, OLD.second_name)
        OR ARRAY['surname', 'name', 'second_name']::text[] && update_of
    THEN
        -- последовательность перечисления частей ФИО важна!
        NEW.gender = gender_by_name(concat_ws(e'\n',
                                              NEW.surname,    --last name
                                              NEW.name,       --first name
                                              NEW.second_name --middle name
                                             ));
    END IF;

    RETURN NEW;
END;
$$;


DROP TRIGGER IF EXISTS person__gender_determine_step1 ON person;
CREATE TRIGGER person__gender_determine_step1
    BEFORE UPDATE OF gender ON person -- поле явно указано в UPDATE запросе
    FOR EACH ROW
    WHEN (OLD.gender IS NOT DISTINCT FROM NEW.gender) --но при этом значение не меняется
    EXECUTE PROCEDURE trigger_save_update_of('gender');

DROP TRIGGER IF EXISTS person__gender_determine_step2 ON person;
CREATE TRIGGER person__gender_determine_step2
    BEFORE UPDATE OF surname, name, second_name ON person -- одно из полей явно указано в UPDATE запросе
    FOR EACH ROW
    WHEN ((OLD.surname, OLD.name, OLD.second_name) IS NOT DISTINCT FROM (NEW.surname, NEW.name, NEW.second_name))
    EXECUTE PROCEDURE trigger_save_update_of('surname', 'name', 'second_name');

DROP TRIGGER IF EXISTS person__gender_determine_step3 ON person;
CREATE TRIGGER person__gender_determine_step3
    BEFORE INSERT OR UPDATE ON person
    FOR EACH ROW
    EXECUTE PROCEDURE gender_determine();
