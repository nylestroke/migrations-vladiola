CREATE OR REPLACE FUNCTION blog.categories_list()
    RETURNS TEXT AS
$BODY$
BEGIN
    RETURN COALESCE( array_to_json(array_agg( cat )), '[]'::json) FROM
        (
            SELECT * FROM blog.categories
        ) as cat;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;