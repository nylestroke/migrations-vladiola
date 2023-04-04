CREATE OR REPLACE FUNCTION auth.user_get( a_id integer )
    RETURNS TEXT AS
$BODY$
BEGIN
    PERFORM 1 FROM auth.users WHERE id = a_id AND active;
    IF NOT FOUND THEN
        RETURN json_build_object('message', 'User did not exists', 'code', 404);
    END IF;

    RETURN row_to_json( u ) FROM (
        SELECT
            id,
            (select name from auth.privileges ap where ap.id = privilege_id) as "privilege",
            active,
            email,
            name,
            surname,
            phone,
            city,
            street,
            house_num,
            postcode,
            company_name,
            nickname,
            created_at,
            modified_at
        FROM auth.users
        WHERE id = a_id
    ) as u;

END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
