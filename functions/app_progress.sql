create or replace function app_progress(
    done_percent numeric, --прогресс выполнения некого запроса
    prefix char default '#', --символ-маркер, после которого должно быть число процентов
    is_local bool default false --false allow pass application_name's value to subtransaction
)
    returns text
    returns null on null input
    parallel unsafe --NOT safe!
    volatile --NOT stable!
    language plpgsql
    set search_path = ''
as
$$
declare
    app_name text;
begin
    app_name := current_setting('application_name');
    app_name := regexp_replace(app_name, concat('\s*\', prefix, '\d+(?:\.\d+)?%'), '');
    app_name := concat(app_name, ' ', prefix, done_percent, '%');
    if octet_length(app_name) > 63 then
        return app_name;
    end if;
    return set_config('application_name', app_name, is_local);
end
$$;


comment on function app_progress(
    done_percent numeric,
    prefix char,
    is_local bool
) is $$
    Дописывает или заменяет прогресс выполнения (в процентах) в application_name.
    Сценарий использования.
      Внутри процедуры с длительным временем работы после выполнения части работы нужно вызывать функцию app_progress().
      Т.о. в списке процессов БД можно наблюдать вашу процедуру и отслеживать ход выполнения.
$$;

--TEST
--select app_progress(0), current_setting('application_name'), app_progress(1), current_setting('application_name');
