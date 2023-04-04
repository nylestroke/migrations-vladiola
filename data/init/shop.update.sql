CREATE OR REPLACE FUNCTION shop.update(a_data character varying)
    RETURNS text AS
$BODY$
BEGIN
    perform shop.units_update(a_data::jsonb->>'units');
    perform shop.categories_update(a_data::jsonb->>'categories');
    perform shop.warehouses_update(a_data::jsonb->>'warehouses');
    perform shop.producers_update(a_data::jsonb->>'producers');
    perform shop.products_init(a_data::jsonb->>'products');

    RETURN jsonb_build_object('code', 200, 'message', 'Database updated successfully');
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
