create function quote_regexp(text) returns text
    stable
    language plpgsql
as
$$
BEGIN
    RETURN REGEXP_REPLACE($1, '([[\](){}.+*^$|\\?-])', '\\\1', 'g');
END;
$$;
