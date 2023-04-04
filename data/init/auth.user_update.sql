CREATE OR REPLACE FUNCTION auth.user_update( a_data character varying )
    RETURNS text AS
$BODY$
DECLARE
    f_id        integer;
    f_data      jsonb;
BEGIN
    f_data  =  a_data::jsonb;
    f_id = COALESCE(CAST( f_data->>'id' as integer ), 0);
    
    PERFORM 1 FROM auth.users WHERE id = f_id AND active;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('message', 'User did not exists', 'code', 404);
    END IF;

    IF (f_data->>'old_password' != '' AND f_data->>'password' = '') OR
       (f_data->>'password' = '' AND f_data->>'old_password' != '') THEN
        RETURN jsonb_build_object('message', 'Old or new passwords are empty', 'code', 400);
    END IF;

    PERFORM 1 FROM auth.users WHERE email = f_data->>'email' AND id <> f_id;
    IF FOUND THEN
        RETURN jsonb_build_object('message', 'Duplicate email', 'code', 409);
    END IF;

    UPDATE auth.users SET
         email    = f_data->>'email',
         name     = f_data->>'name',
         surname  = f_data->>'surname',
         phone    = f_data->>'phone',
         city     = f_data->>'city',
         street  = f_data->>'street',
         house_num  = f_data->>'house_num',
         postcode  = f_data->>'postcode',
         company_name  = f_data->>'company_name',
         nickname  = f_data->>'nickname',
         modified_at  = now()
    WHERE id = f_id AND active;

    IF (f_data->>'old_password' != '' AND f_data->>'password' != '') THEN
        PERFORM 1 FROM auth.users WHERE passwordHash = crypt( f_data->>'old_password', passwordHash ) AND id = f_id AND active;
        IF NOT FOUND THEN
            RETURN jsonb_build_object('message', 'Incorrect old password', 'code', 400);
        END IF;

        UPDATE auth.users SET passwordHash = crypt( f_data->>'password', gen_salt('bf') ) WHERE id = f_id;
    END IF;

    RETURN row_to_json( u ) FROM ( SELECT f_id as id, f_data->>'email' as email ) as u;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
