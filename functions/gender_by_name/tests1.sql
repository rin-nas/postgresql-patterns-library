-- Тесты

DO $$
DECLARE
    rec record;
    result depers.gender;
BEGIN
    for rec in select * from (values
        (null, null),
        ('', 'unknown'),
        ('unknown', 'unknown'),
        ('Неизвестно', 'unknown'),
        ('Фиг Вам', 'unknown'),
        ('ГРЕФ ГЕРМАН', 'male'),
        ('ГЕРМАН ГРЕФ', 'male'),
        ('ГерманОскарович', 'male'),
        ('gref german', 'male'),
        ('Джанатан Эль-Аир Браташ Джи Погоржельский фон Ган Эденом', 'male'),
        ('ЗейналоваИрада', 'female'),
        ('IradaZeinalova', 'female'),
        ('МагрипаХарипулаевна', 'female'),
        ('Анна', 'female'),
        ('АннаПетросян', 'female'),
        ('ПечёрскийЛевПетрович', 'male')) as t(name, gender)
    loop
        result = depers.gender_by_name(rec.name);
        ASSERT
            -- результат сравнения должен вернуть boolean
            result is not distinct from rec.gender::depers.gender,
            -- если результат сравнения не true, то вернётся сообщение с ошибкой
            format('%L expected %L, returned %L', rec.name, rec.gender, result);
    end loop;
END $$;

--тесты от Дмитрия Самохвалова
DO $$
BEGIN
    ASSERT depers.gender_by_name('Сергеев') = 'male';
    ASSERT depers.gender_by_name('Сергеева') = 'female';
    ASSERT depers.gender_by_name('Сергеевич') = 'male';
    ASSERT depers.gender_by_name('Сергеевна') = 'female';
    ASSERT depers.gender_by_name('Олег') = 'male';
    ASSERT depers.gender_by_name('Юля') = 'female';
    ASSERT depers.gender_by_name('Дима') = 'male';
    ASSERT depers.gender_by_name('Викторович Сергеев Олег') = 'male';
    ASSERT depers.gender_by_name('Викторович Олег Сергеев') = 'male';
    ASSERT depers.gender_by_name('Олег Сергеев Викторович') = 'male';
    ASSERT depers.gender_by_name('Олег Викторович Сергеев') = 'male';
    ASSERT depers.gender_by_name('Сергеев Викторович Олег') = 'male';
    ASSERT depers.gender_by_name('Сергеев Олег Викторович') = 'male';

    ASSERT depers.gender_by_name('Викторовна Сергеева Юлия') = 'female';
    ASSERT depers.gender_by_name('Викторовна Олег Сергеева') = /*'unknown'*/ 'female'; -- поведение изменилось, но здесь было неоднозначно

    ASSERT depers.gender_by_name('Белых') = 'unknown';
    ASSERT depers.gender_by_name('Лойе') = 'unknown';
    ASSERT depers.gender_by_name('Граминьи') = 'unknown';
    ASSERT depers.gender_by_name('Чаушеску') = 'unknown';
    ASSERT depers.gender_by_name('Лыхны') = 'unknown';
    ASSERT depers.gender_by_name('Мегрэ') = 'unknown';
    ASSERT depers.gender_by_name('Лю') = 'unknown';

    ASSERT depers.gender_by_name('Остапенко') = 'unknown';
    ASSERT depers.gender_by_name('Анатолий Вассерман') = 'male';
    ASSERT depers.gender_by_name('Вассерман') = 'unknown';
    ASSERT depers.gender_by_name('Гульбахор') = 'unknown';

    ASSERT depers.gender_by_name('Круг') = 'unknown';
    ASSERT depers.gender_by_name('Шок') = 'unknown';
    ASSERT depers.gender_by_name('Мартиросян') = 'unknown';

    ASSERT depers.gender_by_name('Иван Черных') = 'male';
    ASSERT depers.gender_by_name('Круг Черных') = 'unknown';
    ASSERT depers.gender_by_name('Гульбахор Черных') = 'unknown';

    ASSERT depers.gender_by_name('dmitry samohkvalov') = 'male';
    ASSERT depers.gender_by_name('samohkvalov') = 'male';
    ASSERT depers.gender_by_name('dmitry') = 'male';
    ASSERT depers.gender_by_name('dima') = 'male';
    ASSERT depers.gender_by_name('Emma Charlotte Duerre Watson') = 'female';
    ASSERT depers.gender_by_name('Emma Charlotte Watson') = 'female';
    ASSERT depers.gender_by_name('Emma Watson') = 'female';
    ASSERT depers.gender_by_name('Emma') = 'female';
    ASSERT depers.gender_by_name('Watson') = 'unknown';
END $$;

-- определяем пол для ФИО с неоднозначными именами и фамилиями
DO $$
BEGIN
    ASSERT depers.gender_by_name('мороз наталья') = 'female';
    ASSERT depers.gender_by_name('ким александр') = 'male';
    ASSERT depers.gender_by_name('величко ольга') = 'female'; -- по словарю величко - мужское имя, а ольга - женское, но в данном ФИО величко - это фамилия
    ASSERT depers.gender_by_name('ром наталья') = 'female';
    ASSERT depers.gender_by_name('шмидт ольга') = 'female';
    ASSERT depers.gender_by_name('кулик татьяна') = 'female';
    ASSERT depers.gender_by_name('шульга ольга') = 'female';
    ASSERT depers.gender_by_name('король елена') = 'female';
    ASSERT depers.gender_by_name('миллер елена') = 'female';
    ASSERT depers.gender_by_name('таран елена') = 'female';
    ASSERT depers.gender_by_name('бабич елена') = 'female';
    ASSERT depers.gender_by_name('герман анна') = 'female'; --!
    ASSERT depers.gender_by_name('новак александр') = 'male';
    ASSERT depers.gender_by_name('белоус ольга') = 'female';
    ASSERT depers.gender_by_name('сорока александр') = 'male';
    ASSERT depers.gender_by_name('божко наталья') = 'female';
    ASSERT depers.gender_by_name('третьяк елена') = 'female';
    ASSERT depers.gender_by_name('вовк елена') = 'female';
    ASSERT depers.gender_by_name('лебедь александр') = 'male';
    ASSERT depers.gender_by_name('новик елена') = 'female';
    ASSERT depers.gender_by_name('голуб елена') = 'female';
    ASSERT depers.gender_by_name('зозуля сергей') = 'male';
    ASSERT depers.gender_by_name('майер елена') = 'female';
    ASSERT depers.gender_by_name('рева александр') = 'male';
    ASSERT depers.gender_by_name('черныш светлана') = 'female';
    ASSERT depers.gender_by_name('шеремет елена') = 'female';
    ASSERT depers.gender_by_name('казак татьяна') = 'female';
    ASSERT depers.gender_by_name('заяц анна') = 'female';
    ASSERT depers.gender_by_name('шнайдер юлия') = 'female';
    ASSERT depers.gender_by_name('соловей татьяна') = 'female';
    ASSERT depers.gender_by_name('куц наталья') = 'female';
    ASSERT depers.gender_by_name('белан ольга') = 'female';
    ASSERT depers.gender_by_name('глушко анастасия') = 'female';
    ASSERT depers.gender_by_name('черняк наталья') = 'female';
    ASSERT depers.gender_by_name('белик татьяна') = 'female';
    ASSERT depers.gender_by_name('бутко елена') = 'female';
    ASSERT depers.gender_by_name('ворона сергей') = 'male';
END $$;
