CREATE OR REPLACE FUNCTION shop.factory_reset()
    RETURNS text AS
$BODY$
BEGIN
    DELETE FROM shop.products;
    DELETE FROM shop.units;
    DELETE FROM shop.categories;
    DELETE FROM shop.warehouses;
    DELETE FROM shop.producers;
    
    RETURN json_build_object('code', 200);
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
