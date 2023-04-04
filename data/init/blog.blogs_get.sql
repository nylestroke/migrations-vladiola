CREATE OR REPLACE FUNCTION blog.blogs_get(a_id integer)
    RETURNS TEXT AS
$BODY$
BEGIN
    RETURN to_jsonb( u ) FROM (
        SELECT
            id,
            coalesce((select cat.name from blog.categories cat where cat.id = category_id), 'null') as "category",
            title,
            description,
            short_description,
            image,
            created_by,
            created_at
        FROM blog.blogs
        WHERE id = a_id
    ) as u;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;