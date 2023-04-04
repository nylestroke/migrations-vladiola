CREATE OR REPLACE FUNCTION auth.login( aEmail character varying, aPassword character varying )
    RETURNS text AS
$BODY$
DECLARE
    user_rec     RECORD;
    f_privilege    VARCHAR;
BEGIN
    -- Check if database need to be initialized
    PERFORM 1 FROM auth.users;
    IF NOT FOUND THEN
        RETURN  json_build_object('error','Database has a empty registered lists', 'code', 400);
    END IF;

    -- Check user email and password
    SELECT id, email, privilege_id INTO user_rec
    FROM auth.users
    WHERE email = aEmail
      AND active
      AND passwordHash = crypt( aPassword, passwordHash );
    IF NOT FOUND THEN
        RETURN json_build_object('error','Incorrect email or password', 'code', 404);
    END IF;
    
    SELECT name INTO f_privilege FROM auth.privileges WHERE id = user_rec.privilege_id; 

    RETURN json_build_object('id', user_rec.id, 'email', user_rec.email, 'privilege', f_privilege );
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;