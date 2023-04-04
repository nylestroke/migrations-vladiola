CREATE OR REPLACE FUNCTION shop.products_update(a_data character varying)
    RETURNS text AS
$BODY$
DECLARE
    f_rec      record;
    f_data     jsonb;
BEGIN
    f_data = a_data::jsonb;

    FOR f_rec IN
        SELECT p.id, p.cena, p.wyswietlenie, p.ilosc, p.magazyny_ilosc
        FROM jsonb_array_elements(f_data) AS prod,
             jsonb_to_record(prod) AS p(id integer, cena float8, wyswietlenie boolean, ilosc float8,
                                        magazyny_ilosc jsonb)
        ORDER BY p.id
        LOOP
            UPDATE shop.products
            SET price           = f_rec.cena,
                display   = f_rec.wyswietlenie,
                count          = f_rec.ilosc,
                warehouse_count = COALESCE(CAST(f_rec.magazyny_ilosc ->> 'mi' as jsonb), '{}')
            WHERE id = f_rec.id;
        END LOOP;

    RETURN jsonb_build_object('message', 'Products updated successfully', 'code', 200);
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
