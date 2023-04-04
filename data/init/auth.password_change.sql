CREATE OR REPLACE FUNCTION auth.password_change( a_data character varying )
    RETURNS text AS
$BODY$
DECLARE
    f_id    INTEGER;
    f_data  json;
    f_rec   record;
BEGIN
    f_data  =  a_data::json;
    f_id   = cast( f_data->>'id' as integer );
    SELECT passwordHash INTO f_rec FROM auth.users WHERE id = f_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('message', 'Invalid user', 'code', 404);
    END IF;

    IF ( f_data->>'current' IS NULL ) THEN
        RETURN jsonb_build_object('message','Incorrect type of current password', 'code', 409);
    END IF;

    PERFORM 1 FROM auth.users WHERE id = f_id AND passwordHash = crypt( f_data->>'current', f_rec.passwordHash );
    IF NOT FOUND THEN
        RETURN jsonb_build_object('message', 'Current password invalid', 'code', 404);
    END IF;

    UPDATE auth.users SET passwordHash = crypt( f_data->>'password', gen_salt('bf') ) WHERE id = f_id;

    RETURN jsonb_build_object('message', 'Password changed', 'code', 200);
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
