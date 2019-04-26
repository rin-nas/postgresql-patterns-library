create function gender_by_name(first_name character varying, last_name character varying, middle_name character varying) returns gender
    language plpgsql
as
$$
DECLARE
    weight int;
    is_male bool;
    valid_name_regex varchar;
BEGIN
    valid_name_regex := '[а-яё ]{2,}';
    weight := 0;

    first_name := lower(first_name);
    last_name := lower(last_name);
    middle_name := lower(middle_name);

    -- Проверка имени
    IF first_name is not null and first_name similar to valid_name_regex THEN
        select pnd.gender='male' INTO is_male
        from person_name_dictionary pnd
        where lower(pnd.name)=lower($1);

        if is_male THEN
            weight := weight + 1;
        elseif is_male = false THEN
            weight := weight - 1;
        end if;
    END IF;

    -- Проверка отчества
    is_male := null;
    IF middle_name is not null AND middle_name similar to valid_name_regex THEN
        select sbe.gender='male' into is_male
        from gender_by_ending sbe
        where sbe.name_type='middle_name' and right($3, length(sbe.ending)) = sbe.ending;

        if is_male THEN
            weight := weight + 1;
        elseif is_male = false THEN
            weight := weight - 1;
        end if;
    END IF;

    -- Проверка фамилии
    is_male := null;
    IF weight < 2 and last_name is not null and last_name similar to valid_name_regex THEN
        select sbe.gender='male' into is_male
        from gender_by_ending sbe
        where sbe.name_type='last_name' and right($2, length(sbe.ending)) = sbe.ending;

        if is_male THEN
            weight := weight + 1;
        elseif is_male = false THEN
            weight := weight - 1;
        end if;
    END IF;

    if weight = 0 THEN
        RETURN null;
    elseif weight > 0 THEN
        RETURN 'male';
    else
        RETURN 'female';
    end if;

END;
$$;
