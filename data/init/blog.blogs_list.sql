CREATE OR REPLACE FUNCTION blog.blogs_list()
    RETURNS TEXT AS
$BODY$
BEGIN
    RETURN COALESCE( array_to_json(array_agg( blog )), '[]'::json) FROM
        (
            SELECT * FROM blog.blogs
        ) as blog;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;