CREATE OR REPLACE FUNCTION auth.user_delete( a_data character varying )
    RETURNS TEXT AS
$BODY$
DECLARE
    f_data       json;
    f_cnt        integer;
    f_id         integer;
BEGIN
    f_data  =  a_data::json;
    f_id = cast( f_data->>'id' as integer );

    PERFORM 1 FROM auth.users WHERE id = f_id;
    IF NOT FOUND THEN
        RETURN json_build_object('error', 'User did not exist', 'code', 404);
    END IF;

    -- Test if user is last admin in database
    SELECT COUNT(*) INTO f_cnt FROM auth.users;
    IF ( f_cnt <= 1 ) THEN
        RETURN json_build_object('error', 'You cannot delete last user', 'code', 403);
    END IF;

    UPDATE auth.users SET active = false WHERE id = f_id;

    RETURN json_build_object('error', 'User successfully deleted', 'code', 201);
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
