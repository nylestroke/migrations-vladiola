CREATE OR REPLACE FUNCTION auth.password_recover( a_data character varying )
    RETURNS text AS
$BODY$
DECLARE
    f_data       jsonb;
    f_email      varchar;
    f_rec        record;
    f_token      varchar;
BEGIN
    f_data  =  a_data::jsonb;
    f_email  =  COALESCE( f_data->>'email', '');

    -- Validate params
    IF f_email = '' THEN
        perform pg_sleep(2);
        RETURN json_build_object('error', 'Incorrect email', 'code', 400);
    END IF;

    -- Checking if login exists
    SELECT id, email, name, surname, email, recover_token_valid
    INTO f_rec
    FROM auth.users
    WHERE upper(email) = upper(f_email);
    IF NOT FOUND THEN
        perform pg_sleep(2);
        RETURN json_build_object('error', 'Incorrect email', 'code', 400);
    END IF;

    -- Checking for hash ( function should not be called more than once per 5 minute )
    IF COALESCE( f_rec.recover_token_valid, now() - interval '10 minutes') >= now() - interval '5 minutes' THEN
        RETURN jsonb_build_object('error', 'Could not use this more than once per 5 minute', 'code', 403);
    END IF;

    -- Generate some random token
    f_token = MD5 ( gen_salt('bf', 8) );

    UPDATE auth.users
    SET recover_token = crypt ( f_token, gen_salt('bf', 12) ),
        recover_token_valid = now()
    WHERE id = f_rec.id;

    RETURN json_build_object(
            'recover_token', f_token,
            'email', f_rec.email,
            'name', f_rec.name,
            'surname', f_rec.surname
        );

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;