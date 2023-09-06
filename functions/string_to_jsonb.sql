create or replace function public.string_to_jsonb(str text)
    returns jsonb
    returns null on null input
    parallel unsafe --(ERROR:  cannot start subtransactions during a parallel operation)
    stable
    language plpgsql
    set search_path = ''
    cost 5
as
$$
BEGIN
    BEGIN
        RETURN str::jsonb;
    EXCEPTION WHEN others THEN
        RETURN NULL;
    END;
END;
$$;

comment on function public.string_to_jsonb(str text) is $$
    Converts JSON syntax from string to jsonb type.
    For invalid JSON syntax returns NULL rather error.
$$;

--TEST
do $$
    begin
        --positive
        assert jsonb_typeof(public.string_to_jsonb('null')) = 'null';
        assert jsonb_typeof(public.string_to_jsonb('true')) = 'boolean';
        assert jsonb_typeof(public.string_to_jsonb('false')) = 'boolean';
        assert jsonb_typeof(public.string_to_jsonb('0')) = 'number';
        assert jsonb_typeof(public.string_to_jsonb('-0.1')) = 'number';
        assert jsonb_typeof(public.string_to_jsonb('""')) = 'string';
        assert jsonb_typeof(public.string_to_jsonb('[]')) = 'array';
        assert jsonb_typeof(public.string_to_jsonb('[1,2]')) = 'array';
        assert jsonb_typeof(public.string_to_jsonb('{}')) = 'object';
        assert jsonb_typeof(public.string_to_jsonb('{"":0}')) = 'object';

        --negative
        assert jsonb_typeof(public.string_to_jsonb(null)) is null;
        assert jsonb_typeof(public.string_to_jsonb('')) is null;
        assert jsonb_typeof(public.string_to_jsonb('{"oops"}')) is null;
        assert jsonb_typeof(public.string_to_jsonb('[,]')) is null;
    end
$$;
