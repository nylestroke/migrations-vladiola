CREATE OR REPLACE FUNCTION shop.producers_update(a_data character varying)
    RETURNS text AS
$BODY$
DECLARE
    f_rec      record;
    f_data     jsonb;
BEGIN
    f_data = a_data::jsonb;

    FOR f_rec IN
        SELECT prod.id,
               prod.nazwa,
               prod.pr_title,
               prod.pr_description,
               prod.pr_keywords
        FROM jsonb_array_elements(f_data) AS producers,
             jsonb_to_record(producers) AS prod(id integer, nazwa varchar, pr_title jsonb, pr_description jsonb, pr_keywords jsonb)
        ORDER BY prod.id
        LOOP
            PERFORM 1 FROM shop.producers WHERE id = f_rec.id;
            IF NOT FOUND THEN
                INSERT INTO shop.producers (id, name, title, description, keywords)
                VALUES (f_rec.id, f_rec.nazwa, f_rec.pr_title->>'value', f_rec.pr_description->>'value', f_rec.pr_keywords->>'value');
            ELSE
                UPDATE shop.producers SET name = f_rec.nazwa, title = f_rec.pr_title->>'value', description = f_rec.pr_description->>'value', 
                                      keywords = f_rec.pr_keywords->>'value' 
                WHERE id = f_rec.id;
            END IF;
        END LOOP;

    RETURN jsonb_build_object('code', 200, 'message', 'Product producers initialized successfully');
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
