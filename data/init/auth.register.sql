CREATE OR REPLACE FUNCTION auth.register( a_data character varying )
    RETURNS text AS
$BODY$
DECLARE
    f_data          jsonb;
    f_id            integer;
    f_email         varchar;
    f_name          varchar;
    f_surname       varchar;
    f_password      varchar;
BEGIN
    f_data  =  a_data::jsonb;
    f_email  =  COALESCE(CAST(f_data->>'email' as varchar), '');
    f_name  =  COALESCE(CAST(f_data->>'name' as varchar), '');
    f_surname  =  COALESCE(CAST(f_data->>'surname' as varchar), '');
    f_password  =  COALESCE(CAST(f_data->>'password' as varchar), '');
    
    IF f_email = '' OR f_name = '' OR f_surname = '' OR f_password = '' THEN
        RETURN json_build_object('message', 'Invalid parameters', 'code', 400);
    END IF;
    
    PERFORM 1 FROM auth.users WHERE email = f_email;
    IF FOUND THEN
        RETURN jsonb_build_object('message', 'Duplicate email', 'code', 409);
    END IF;
    
    f_id = nextval(('users_seq'::text)::regclass);
    INSERT INTO auth.users (
        id,
        email,
        name,
        surname,
        created_at
    ) VALUES (
        f_id,
        f_email,
        f_name,
        f_surname,
        now()
    );

    -- Update password
    UPDATE auth.users SET
        passwordHash = crypt( f_password, gen_salt('bf') ),
        modified_at = now()
    WHERE id = f_id;

    RETURN row_to_json( u ) FROM ( SELECT f_id as id, f_email as email ) as u;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;