-- Тестирование работы новых триггеров и функций, часть 2
do $$
    declare
        rec record;
    begin

        insert into person (name, surname, second_name)
        select 'Александр'     as name,
               'Филов'         as surname,
               'Александрович' as second_name
        returning * into rec;

        raise notice '%', row_to_json(rec);
        assert rec.gender = 'male';

        ----------------------------------
        UPDATE person
        SET name        = 'Александр',
            surname     = 'Филов',
            second_name = 'Александрович'
        where id = rec.id
        returning * into rec;

        raise notice '1 %', row_to_json(rec);
        assert rec.gender = 'male';

        ----------------------------------
        UPDATE person
        SET name        = 'Александра',
            surname     = 'Филова',
            second_name = 'Александровна'
        where id = rec.id
        returning * into rec;

        raise notice '2 %', row_to_json(rec);
        assert rec.gender = 'female';

        ----------------------------------
        UPDATE person
        SET name        = 'Александр',
            surname     = 'Филов',
            second_name = 'Александрович',
            gender = 'male'
        where id = rec.id
        returning * into rec;

        raise notice '3 %', row_to_json(rec);
        assert rec.gender = 'male';

        ----------------------------------
        UPDATE person
        SET name        = 'Александра',
            surname     = 'Филова',
            second_name = 'Александровна',
            gender = 'female'
        where id = rec.id
        returning * into rec;

        raise notice '4 %', row_to_json(rec);
        assert rec.gender = 'female';

        ----------------------------------
        UPDATE person
        SET name        = 'Александр',
            surname     = 'Филов',
            second_name = 'Александрович',
            gender = 'female'
        where id = rec.id
        returning * into rec;

        raise notice '5 %', row_to_json(rec);
        assert rec.gender = 'female';

        ----------------------------------
        UPDATE person
        SET name        = 'Александра',
            surname     = 'Филова',
            second_name = 'Александровна',
            gender = 'male'
        where id = rec.id
        returning * into rec;

        raise notice '6 %', row_to_json(rec);
        assert rec.gender = 'male';

        -- теперь те же запросы, но в обратной последовательности:

        ----------------------------------
        UPDATE person
        SET name        = 'Александра',
            surname     = 'Филова',
            second_name = 'Александровна',
            gender = 'male'
        where id = rec.id
        returning * into rec;

        raise notice '6 %', row_to_json(rec);
        assert rec.gender = 'male';

        ----------------------------------
        UPDATE person
        SET name        = 'Александр',
            surname     = 'Филов',
            second_name = 'Александрович',
            gender = 'female'
        where id = rec.id
        returning * into rec;

        raise notice '5 %', row_to_json(rec);
        assert rec.gender = 'female';

        ----------------------------------
        UPDATE person
        SET name        = 'Александра',
            surname     = 'Филова',
            second_name = 'Александровна',
            gender = 'female'
        where id = rec.id
        returning * into rec;

        raise notice '4 %', row_to_json(rec);
        assert rec.gender = 'female';

        ----------------------------------
        UPDATE person
        SET name        = 'Александр',
            surname     = 'Филов',
            second_name = 'Александрович',
            gender = 'male'
        where id = rec.id
        returning * into rec;

        raise notice '3 %', row_to_json(rec);
        assert rec.gender = 'male';

        ----------------------------------
        UPDATE person
        SET name        = 'Александра',
            surname     = 'Филова',
            second_name = 'Александровна'
        where id = rec.id
        returning * into rec;

        raise notice '2 %', row_to_json(rec);
        assert rec.gender = 'female';

        ----------------------------------
        UPDATE person
        SET name        = 'Александр',
            surname     = 'Филов',
            second_name = 'Александрович'
        where id = rec.id
        returning * into rec;

        raise notice '1 %', row_to_json(rec);
        assert rec.gender = 'male';

        ----------------------------------
        delete from person where id = rec.id;

    end
$$;
