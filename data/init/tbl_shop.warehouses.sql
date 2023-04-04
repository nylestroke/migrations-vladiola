CREATE TABLE shop.warehouses (
    id integer not null primary key,
    name varchar not null,
    position integer not null,
    allowed_orders_zero integer not null,
    "default" boolean not null,
    description varchar not null
);

COMMENT ON TABLE shop.warehouses IS 'List of warehouses for products';