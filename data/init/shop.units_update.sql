CREATE OR REPLACE FUNCTION shop.units_update(a_data character varying)
    RETURNS text AS
$BODY$
DECLARE
    f_rec      record;
    f_data     jsonb;
BEGIN
    f_data = a_data::jsonb;

    FOR f_rec IN
        SELECT unit.id,
               unit.skrot
        FROM jsonb_array_elements(f_data) AS units,
             jsonb_to_record(units) AS unit(id integer, skrot varchar)
        ORDER BY unit.id
        LOOP
            PERFORM 1 FROM shop.units WHERE id = f_rec.id;
            IF NOT FOUND THEN
                INSERT INTO shop.units (id, abbreviation)
                VALUES (f_rec.id, f_rec.skrot);
            ELSE
                UPDATE shop.units SET abbreviation = f_rec.skrot WHERE id = f_rec.id;
            END IF;
        END LOOP;

    RETURN jsonb_build_object('code', 200, 'message', 'Units initialized successfully');
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
