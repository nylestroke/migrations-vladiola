CREATE TABLE shop.units (
    id integer not null primary key,
    abbreviation varchar not null
);

COMMENT ON TABLE shop.units IS 'List of units for products';