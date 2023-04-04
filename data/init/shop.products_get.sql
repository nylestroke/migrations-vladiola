CREATE OR REPLACE FUNCTION shop.products_get(a_id integer)
    RETURNS TEXT AS
$BODY$
BEGIN
    RETURN to_jsonb(product) FROM 
        (
        SELECT id, vat_rate, count, weight, title, vendor_code, producer_code, product_symbol, html_title,
               description, delivery, photos, discount,
               (case when discount is not null then cast((price2 * 1.3) as float8) else price2 end) as "price",
               coalesce(cast(warehouse_count->>'ilosc' as float8), 0) as "warehouse_count",
               coalesce((select row_to_json(cat.*) from shop.categories cat where cat.id = category_id), '{}') as "category",
               coalesce((select row_to_json(prod.*) from shop.producers prod where prod.id = producer_id), '{}') as "producer",
               coalesce((select row_to_json(ware.*) from shop.warehouses ware where ware.id = warehouse_id), '{}') as "warehouse",
               coalesce((select array_to_json(array_agg(rev.*)) from shop.reviews rev where rev.product_id = a_id), '[]'::json) as "reviews",
               coalesce((select un.abbreviation from shop.units un where un.id = unit_id), 'null') as "unit"
        FROM shop.products WHERE id = a_id
        ) as product;
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
