CREATE OR REPLACE FUNCTION shop.warehouses_update(a_data character varying)
    RETURNS text AS
$BODY$
DECLARE
    f_data     jsonb;
BEGIN
    f_data = a_data::jsonb;

    PERFORM 1 FROM shop.warehouses WHERE id = CAST(f_data->>'id' as integer);
    IF NOT FOUND THEN
        INSERT INTO shop.warehouses (id, name, position, allowed_orders_zero, "default", description)
        VALUES (CAST(f_data->>'id' as integer), f_data->>'nazwa', CAST(f_data->>'pozycja' as integer),
                CAST(f_data->>'dozwolone_zamowienia_zero' as integer),
                CAST(f_data->>'domyslny' as boolean),
                CAST(f_data->>'m_opis' as jsonb)->>'value');
    ELSE
        UPDATE shop.warehouses SET name = f_data->>'nazwa', position = CAST(f_data->>'pozycja' as integer),
                                allowed_orders_zero = CAST(f_data->>'dozwolone_zamowienia_zero' as integer),
                                "default" = CAST(f_data->>'domyslny' as boolean),
                                   description = CAST(f_data->>'m_opis' as jsonb)->>'value'
        WHERE id = CAST(f_data->>'id' as integer);
    END IF;

    RETURN jsonb_build_object('code', 200, 'message', 'Magazyny initialized successfully');
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
