-- https://stackoverflow.com/questions/5144036/escape-function-for-regular-expression-or-like-patterns/45741630#45741630
create function quote_regexp(text) returns text
    stable
    language plpgsql
as
$$
BEGIN
    RETURN REGEXP_REPLACE($1, '([[\](){}.+*^$|\\?-])', '\\\1', 'g');
END;
$$;
