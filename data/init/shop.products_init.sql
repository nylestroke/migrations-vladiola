CREATE OR REPLACE FUNCTION shop.products_init(a_data character varying)
    RETURNS text AS
$BODY$
DECLARE
    f_rec      record;
    f_cnt      integer;
    f_data     jsonb;
    f_ranDisc  float8;
BEGIN
    f_data = a_data::jsonb;
    
    SELECT COUNT(*) INTO f_cnt FROM shop.products;
    IF f_cnt > 0 THEN
        RETURN json_build_object('code', '406', 'message', 'Database already initialized with products');
    END IF;

    FOR f_rec IN
        SELECT p.id,
               p.kategoria_id,
               p.producent_id,
               p.cena,
               p.wyswietlenie,
               p.zestaw,
               p.cena_poprzednia,
               p.stawka_vat,
               p.magazyn_id,
               p.ilosc,
               p.waga,
               p.gabaryt,
               p.cena1,
               p.cena2,
               p.ilosc_dokladnosc,
               p.ilosc_min,
               p.ilosc_przyrost,
               p.jm,
               p.do_porownywarek,
               p.nazwa,
               p.kod_dostawcy,
               p.kod_producenta,
               p.symbol_produktu,
               p.html_title,
               p.opis,
               p.promocja_kategorii,
               p.dostawa,
               p.zdjecia,
               p.magazyny_ilosc
        FROM jsonb_array_elements(f_data) AS prod,
             jsonb_to_record(prod) AS p(id integer, kategoria_id integer, producent_id integer, cena float8,
                                        wyswietlenie boolean, zestaw integer,
                                        cena_poprzednia float8, stawka_vat float8, magazyn_id integer, ilosc float8,
                                        waga float8,
                                        gabaryt varchar, cena1 float8, cena2 float8, ilosc_dokladnosc float8,
                                        ilosc_min float8,
                                        ilosc_przyrost float8, jm float8, do_porownywarek boolean, nazwa jsonb,
                                        kod_dostawcy jsonb,
                                        kod_producenta jsonb, symbol_produktu jsonb, html_title jsonb, opis jsonb,
                                        promocja_kategorii varchar, dostawa jsonb, zdjecia jsonb, magazyny_ilosc jsonb)
        ORDER BY p.id
        LOOP
            IF f_rec.producent_id = 0 THEN
                f_rec.producent_id = null;
            END IF;
            
            IF cast(f_rec.magazyny_ilosc->>'mi' as jsonb)->>'ilosc' = '' THEN
                perform jsonb_set(f_rec.magazyny_ilosc, '{mi, ilosc}', '"0.00"');
            END IF;

            select cast(cast(random_between(115, 123) as float8) / 100 as float8) into f_ranDisc;
            f_ranDisc = floor(cast(cast(f_rec.cena2 as float8) * 1.3 as float8) * f_ranDisc);
            
            IF cast((f_rec.cena2 * 1.3) as float8) < 180 THEN
                f_ranDisc = null;
            END IF;
            
            INSERT INTO shop.products (id, category_id, producer_id, price, display, kit, previous_price,
                                  vat_rate, warehouse_id, count, weight, dimensions, price1, price2, count_accuracy, count_min, count_increment, unit_id,
                                  to_comparisons, title, vendor_code,
                                  producer_code, product_symbol, html_title, description, category_promotion, delivery,
                                  photos, warehouse_count, discount)
            VALUES (f_rec.id, f_rec.kategoria_id, f_rec.producent_id, f_rec.cena, f_rec.wyswietlenie, f_rec.zestaw,
                    f_rec.cena_poprzednia,
                    f_rec.stawka_vat, f_rec.magazyn_id, f_rec.ilosc, f_rec.waga, f_rec.gabaryt, f_rec.cena1,
                    f_rec.cena2, f_rec.ilosc_dokladnosc,
                    f_rec.ilosc_min, f_rec.ilosc_przyrost, f_rec.jm, f_rec.do_porownywarek, f_rec.nazwa ->> 'value',
                    f_rec.kod_dostawcy ->> 'value',
                    f_rec.kod_producenta ->> 'value', f_rec.symbol_produktu ->> 'value', f_rec.html_title ->> 'value',
                    f_rec.opis ->> 'value', f_rec.promocja_kategorii,
                    f_rec.dostawa ->> 'value', COALESCE(CAST(f_rec.zdjecia ->> 'z' as jsonb), '[]'),
                    COALESCE(CAST(f_rec.magazyny_ilosc ->> 'mi' as jsonb), '{}'), f_ranDisc);
        END LOOP;

    RETURN jsonb_build_object('code', 200, 'message', 'Products initialized successfully');
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
