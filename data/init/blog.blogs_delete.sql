CREATE OR REPLACE FUNCTION blog.blogs_delete( a_id integer )
    RETURNS TEXT AS
$BODY$
BEGIN
    PERFORM 1 FROM blog.blogs WHERE id = a_id;
    IF NOT FOUND THEN
        RETURN jsonb_build_object('error', 'Blog did not exists', 'code', 404);
    END IF;
    BEGIN
        DELETE FROM blog.blogs WHERE id = a_id;
    EXCEPTION WHEN OTHERS THEN
        RETURN jsonb_build_object('error', 'Cannot delete item', 'code', 403);
    END;
    RETURN jsonb_build_object('code', 202 );
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;