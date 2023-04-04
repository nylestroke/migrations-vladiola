CREATE OR REPLACE FUNCTION shop.reviews_save( a_data character varying )
    RETURNS text AS
$BODY$
DECLARE
    f_id    integer;
    f_data  jsonb;
BEGIN
    f_data = a_data::jsonb;

    f_id = nextval('reviews_seq'::regclass);
    INSERT INTO shop.reviews (
        id,
        product_id,
        opinion,
        message,
        name,
        email,
        created_at
    ) VALUES (
        f_id,
        CAST( f_data->>'product_id' as INTEGER),
        CAST( f_data->>'opinion' as INTEGER),
        f_data->>'message',
        f_data->>'name',
        f_data->>'email',
        now()
    );

    RETURN jsonb_build_object('id', f_id, 'code', 200 );
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
