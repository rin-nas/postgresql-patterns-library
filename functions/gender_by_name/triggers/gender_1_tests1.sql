-- Тестирование работы новых триггеров и функций, часть 1
do $$
    declare
        rec record;
    begin

        raise notice '%', 'Добавляем запись. Пол определяется автоматически по ФИО';

        insert into person (name, surname, second_name)
        select 'Анита'  as name,
               'Цой'    as surname,
               null     as second_name
        returning * into rec;

        raise notice '%', row_to_json(rec);
        assert rec.gender = 'female';


        raise notice '%', 'Обновляем запись. Пол определяется автоматически при замене ФИО';

        update person set name = 'Виктор' where id = rec.id
        returning * into rec;

        raise notice '%', row_to_json(rec);
        assert rec.gender = 'male';

        delete from person where id = rec.id;

    end
$$;


do $$
    declare
        rec record;
    begin

        raise notice '%', 'Добавляем запись. Пол устанавливаем принудительно male';

        insert into person (name, surname, second_name, gender)
        select 'Анита'  as name,
               'Цой'    as surname,
               null     as second_name,
               'male'   as gender
        returning * into rec;

        raise notice '%', row_to_json(rec);
        assert rec.gender = 'male';


        raise notice '%', 'Обновляем запись. Пол устанавливаем принудительно unknown';

        update person set name = 'Виктор', gender = 'unknown' where id = rec.id
        returning * into rec;

        raise notice '%', row_to_json(rec);
        assert rec.gender = 'unknown';


        raise notice '%', 'Обновляем запись. Пол определяется автоматическти по ФИО при сбросе пола';

        update person set gender = null where id = rec.id
        returning * into rec;

        raise notice '%', row_to_json(rec);
        assert rec.gender = 'male';

        delete from person where id = rec.id;

    end
$$;
