CREATE OR REPLACE FUNCTION auth.user_list()
    RETURNS TEXT AS
$BODY$
BEGIN    
    RETURN array_to_json(array_agg( u )) FROM
        (
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
        ) as u;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;