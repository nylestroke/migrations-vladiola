CREATE OR REPLACE FUNCTION auth.password_reset( a_data character varying )
    RETURNS text AS
$BODY$
DECLARE
    f_data      json;
    f_rec       record;
    f_email     varchar;
    f_token     varchar;
    f_password  varchar;
    f_cnt       integer;
BEGIN
    f_data  =  a_data::json;
    f_email = COALESCE( f_data->>'email', '' );
    f_token = COALESCE( f_data->>'recover_token', '' );
    f_password = COALESCE( f_data->>'password', '' );

    -- Validate
    IF ( f_email = '' ) OR
       ( f_token = '' ) OR
       ( f_password = '' )
    THEN
        RETURN json_build_object('error', 'Invalid parameters', 'code', 400);
    END IF;

    SELECT id, email, password, recover_token_valid
    INTO f_rec
    FROM auth.users
    WHERE upper(email) = upper(f_email)
      AND recover_token = crypt( f_token, recover_token );
    IF NOT FOUND THEN
        PERFORM pg_sleep(2);
        RETURN json_build_object('error', 'Incorrect data', 'code', 400);
    END IF;

    -- Checking hash expiration ( 3 hours )
    IF COALESCE( f_rec.recover_token_valid, now() ) >= now() + interval '3 hours' THEN
        RETURN json_build_object(
                'error', 'Password change token expired. It is valid only 3 hours.',
                'code', 403
            );
    END IF;

    UPDATE auth.users
    SET recover_token = null,
        recover_token_valid = now(),
        passwordHash = crypt( f_password, gen_salt('bf', 12) )
    WHERE id = f_rec.id;

    GET DIAGNOSTICS f_cnt = ROW_COUNT;

    IF f_cnt = 0 THEN
        RETURN json_build_object(
                'error', 'There was problem during changing password',
                'code', 406
            );
    END IF;

    RETURN json_build_object('message', 'Password has been changed.', 'code', 200);

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;