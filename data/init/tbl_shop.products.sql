﻿CREATE TABLE shop.products (
    id integer not null primary key,
    category_id integer not null references shop.categories(id),
    producer_id integer null default null references shop.producers(id),
    warehouse_id integer not null references shop.warehouses(id),
    unit_id integer not null references shop.units(id),
    price float8  null,
    display boolean null,
    kit integer null,
    previous_price float8  null,
    vat_rate float8  null,
    count float8  null,
    weight float8  null,
    dimensions varchar null,
    price1 float8  null,
    price2 float8  null,
    count_accuracy float8  null,
    count_min float8  null,
    count_increment float8  null,
    to_comparisons boolean null,
    title varchar null,
    vendor_code varchar null,
    producer_code varchar null,
    product_symbol varchar null,
    html_title varchar null,
    description varchar null,
    category_promotion varchar null,
    delivery varchar null,
    photos jsonb null,
    warehouse_count jsonb null,
    discount integer null
);
COMMENT ON TABLE shop.products IS 'List of vivab2b products';