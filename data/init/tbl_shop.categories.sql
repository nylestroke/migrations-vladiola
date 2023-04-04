CREATE TABLE shop.categories (
    id integer not null primary key,
    name varchar not null,
    position integer not null,
    product_weight float8 not null,
    product_dimension float8 not null,
    kgo float8 not null,
    path varchar not null,
    title varchar null,
    short_description varchar null,
    description varchar null
);

COMMENT ON TABLE shop.categories IS 'List of categories for products';