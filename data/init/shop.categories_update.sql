CREATE OR REPLACE FUNCTION shop.categories_update(a_data character varying)
    RETURNS text AS
$BODY$
DECLARE
    f_rec      record;
    f_data     jsonb;
BEGIN
    f_data = a_data::jsonb;

    FOR f_rec IN
        SELECT cat.id,
               cat.nazwa,
               cat.pozycja,
               cat.produkt_waga,
               cat.produkt_gabaryt,
               cat.kgo,
               cat.sciezka,
               cat.k_title,
               cat.k_description,
               cat.k_opis
        FROM jsonb_array_elements(f_data) AS categories,
             jsonb_to_record(categories) AS cat(id integer, nazwa varchar, pozycja integer, produkt_waga float8,
                                            produkt_gabaryt float8, kgo float8, sciezka varchar, k_title jsonb,
                                            k_description jsonb, k_opis jsonb)
        ORDER BY cat.id
        LOOP
            PERFORM 1 FROM shop.categories WHERE id = f_rec.id;
            IF NOT FOUND THEN
                INSERT INTO shop.categories (id, name, position, product_weight, product_dimension, kgo, path, title,
                                       short_description, description)
                VALUES (f_rec.id, f_rec.nazwa, f_rec.pozycja, f_rec.produkt_waga, f_rec.produkt_gabaryt, f_rec.kgo,
                        f_rec.sciezka, f_rec.k_title->>'value', f_rec.k_description->>'value', f_rec.k_opis->>'value');
            ELSE
                UPDATE shop.categories SET name = f_rec.nazwa, position = f_rec.pozycja, product_weight = f_rec.produkt_waga, product_dimension = f_rec.produkt_gabaryt,
                                     kgo = f_rec.kgo, path = f_rec.sciezka, title = f_rec.k_title->>'value', short_description = f_rec.k_description->> 'value',
                                     description = f_rec.k_opis->> 'value' 
                WHERE id = f_rec.id;
            END IF;
        END LOOP;

    RETURN jsonb_build_object('code', 200, 'message', 'Product categories initialized successfully');
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
