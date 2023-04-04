CREATE OR REPLACE FUNCTION shop.categories_list()
    RETURNS TEXT AS
$BODY$
DECLARE 
    f_data json;
    f_cnt integer;
BEGIN
    f_data = COALESCE( array_to_json(array_agg( cat )), '[]'::json) FROM
        (
            SELECT DISTINCT on (categ.name) 
                coalesce((select array_to_json(array_agg( c.id )) from shop.categories c where c.name = categ.name), '[]'::json) as "id", 
                coalesce((select count(*) from shop.products pr where pr.category_id = categ.id group by categ.id), 0) as "productsCount", 
                categ.name 
            FROM shop.categories categ
        ) as cat;

    SELECT COUNT(*) INTO f_cnt FROM json_array_elements(f_data);
    RETURN json_build_object('data', f_data, 'cnt', f_cnt);
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;