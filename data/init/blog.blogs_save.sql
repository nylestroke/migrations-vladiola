CREATE OR REPLACE FUNCTION blog.blogs_save( a_data character varying )
    RETURNS text AS
$BODY$
DECLARE
    f_id    integer;
    f_data  jsonb;
BEGIN
    f_data = a_data::jsonb;
    f_id   = COALESCE( CAST( f_data->>'id' as INTEGER ), 0);

    IF f_id > 0 THEN
        PERFORM 1 FROM blog.blogs WHERE id = f_id;
        IF NOT FOUND THEN
            RETURN jsonb_build_object('error', 'Blog did not exists', 'code', 404);
        END IF;
        UPDATE blog.blogs SET
              category_id = CAST( f_data->>'category_id' as INTEGER),
              title = f_data->>'title',
              description = f_data->>'description',
              short_description = f_data->>'short_description',
              image = f_data->>'image',
              created_by = f_data->>'created_by',
              created_at = now()
        WHERE id = f_id;
    ELSE
        f_id = nextval('blogs_seq'::regclass);
        INSERT INTO blog.blogs (
            id,
            category_id,
            title,
            description,
            short_description,
            image,
            created_by,
            created_at
        ) VALUES (
             f_id,
             CAST( f_data->>'category_id' as INTEGER),
             f_data->>'title',
             f_data->>'description',
             f_data->>'short_description',
             f_data->>'image',
             f_data->>'created_by',
             now()
        );
    END IF;

    RETURN jsonb_build_object('id', f_id, 'code', 200 );
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
