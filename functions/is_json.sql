create or replace function public.is_json(str text, is_notice boolean default false)
    returns boolean
    returns null on null input
    parallel unsafe --(ERROR:  cannot start subtransactions during a parallel operation)
    stable
    language plpgsql
    set search_path = ''
    cost 5
as
$$
DECLARE
    exception_sqlstate text;
    exception_message text;
    exception_context text;
BEGIN
    BEGIN
        RETURN (str::json is not null);
    EXCEPTION WHEN others THEN
        IF is_notice THEN
            GET STACKED DIAGNOSTICS
                exception_sqlstate := RETURNED_SQLSTATE,
                exception_message  := MESSAGE_TEXT,
                exception_context  := PG_EXCEPTION_CONTEXT;
            RAISE NOTICE 'exception_sqlstate = %', exception_sqlstate;
            RAISE NOTICE 'exception_context = %', exception_context;
            RAISE NOTICE 'exception_message = %', exception_message;
        END IF;
        RETURN FALSE;
    END;
END;
$$;

comment on function public.is_json(str text, is_notice boolean) is 'Checks JSON syntax for input string';

--TEST
do $$
    begin
        --positive
        assert public.is_json('null');
        assert public.is_json('true');
        assert public.is_json('false');
        assert public.is_json('0');
        assert public.is_json('-0.1');
        assert public.is_json('""');
        assert public.is_json('[]');
        assert public.is_json('{}');
        --negative
        assert not public.is_json('');
        assert not public.is_json('{oops}');
    end
$$;
