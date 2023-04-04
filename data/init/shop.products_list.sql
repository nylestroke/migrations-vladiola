CREATE OR REPLACE FUNCTION shop.products_list(a_filter character varying)
    RETURNS TEXT AS
$BODY$
DECLARE
    f_request             jsonb;
    f_filter              jsonb;
    f_p_size              integer;
    f_p_offset            integer;
    f_order               varchar;
    f_sort                varchar;
    f_sql                 varchar;
    f_result              jsonb;
    f_cnt                 integer;
    f_sql_where           varchar;
    f_sql_order           varchar;
    f_valid_search_fields varchar[];
    f_filter_field_type   varchar;
BEGIN
    f_valid_search_fields =
            '{"title","html_title","category_id","description","delivery","discount","price","price1","price2"}'::varchar[];
    f_request = CAST(a_filter as jsonb);
    f_p_size = (f_request ->> 'page_size')::integer;
    f_p_offset = (f_request ->> 'page_index')::integer * f_p_size;
    f_order = f_request ->> 'sort_direction';
    IF (NOT ((f_order = 'asc') OR (f_order = 'desc') OR (f_order = ''))) THEN
        RETURN jsonb_build_object('message', 'Wrong order', 'code', 400);
    END IF;

    f_sql_where = '';
    FOR f_filter IN
        SELECT * FROM jsonb_array_elements(f_request -> 'filter')
        LOOP
            IF NOT CAST(f_filter ->> 'field' as varchar) = ANY (f_valid_search_fields) THEN
                RETURN jsonb_build_object('error', 'Wrong filter field', 'code', 400);
            END IF;
            SELECT data_type
            INTO f_filter_field_type
            FROM information_schema.columns
            WHERE table_name = 'products'
              AND table_schema = 'shop'
              AND column_name = CAST(f_filter ->> 'field' as varchar);
            IF f_filter_field_type = 'character varying' THEN
                f_sql_where = f_sql_where || ' AND upper(' || CAST(f_filter ->> 'field' as varchar) || ') LIKE ' ||
                              quote_literal('%' || upper(f_filter ->> 'value') || '%');
            ELSEIF f_filter_field_type = 'boolean' THEN
                f_sql_where = f_sql_where || ' AND ' || CAST(f_filter ->> 'field' as varchar) || ' = ' ||
                              CAST(f_filter ->> 'value' as varchar);
            ELSEIF f_filter_field_type = 'integer' THEN
                IF position(CAST(f_filter ->> 'field' as varchar) in f_sql_where) > 0 THEN
                    f_sql_where = f_sql_where || ' OR ' || CAST(f_filter ->> 'field' as varchar) || ' = ' ||
                                  CAST(f_filter ->> 'value' as integer);
                ELSE
                        f_sql_where = f_sql_where || ' AND ' || CAST(f_filter ->> 'field' as varchar) || ' = ' ||
                                      CAST(f_filter ->> 'value' as integer);
                END IF;
            ELSE
                RETURN jsonb_build_object('message', 'Wrong filter field type', 'code', 400);
            END IF;
        END LOOP;

    f_sql_order = '';
    FOR f_sort IN
        SELECT * FROM jsonb_array_elements_text(f_request -> 'sort')
        LOOP
            IF NOT CAST(f_sort as varchar) = ANY (f_valid_search_fields) THEN
                RETURN jsonb_build_object('message', 'Wrong sort field', 'code', 400);
            END IF;
            IF (f_sql_order = ''::varchar) THEN
                f_sql_order = f_sql_order || f_sort;
            ELSE
                f_sql_order = f_sql_order || ',' || f_sort;
            END IF;
        END LOOP;
    IF (f_sql_order <> '') THEN
        f_sql_order = ' ORDER BY ' || f_sql_order || ' ' || f_order;
    END IF;
    
    f_sql_where  = f_sql_where || ' and price2 is not null and warehouse_count->>''ilosc'' != '''' and count <> 0';

    f_sql = format('SELECT COALESCE(to_jsonb(array_agg( u )),''[]''::jsonb) FROM (
        SELECT id, vat_rate, count, weight, title, vendor_code, producer_code, product_symbol, html_title,
               description, delivery, photos, discount,
               (case when discount is not null then cast((price2 * 1.3) as float8) else price2 end) as "price",
               coalesce(cast(warehouse_count->>''ilosc'' as float8), 0) as "warehouse_count",
               coalesce((select row_to_json(cat.*) from shop.categories cat where cat.id = category_id), ''{}'') as "category",
               coalesce((select row_to_json(prod.*) from shop.producers prod where prod.id = producer_id), ''{}'') as "producer",
               coalesce((select row_to_json(ware.*) from shop.warehouses ware where ware.id = warehouse_id), ''{}'') as "warehouse",
               coalesce((select un.abbreviation from shop.units un where un.id = unit_id), ''null'') as "unit"
        FROM shop.products
    WHERE TRUE %s
    %s
    LIMIT $1
    OFFSET $2
  ) as u', f_sql_where, f_sql_order);
    EXECUTE f_sql INTO f_result USING f_p_size, f_p_offset;
    SELECT COUNT(*) INTO f_cnt FROM jsonb_array_elements(f_result);
    RETURN jsonb_build_object('data', f_result, 'cnt', f_cnt);
END;
$BODY$
    LANGUAGE plpgsql VOLATILE
                     COST 100;
