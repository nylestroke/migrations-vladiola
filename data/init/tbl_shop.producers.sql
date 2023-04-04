CREATE TABLE shop.producers (
    id integer not null primary key,
    name varchar not null,
    title varchar null,
    description varchar null,
    keywords varchar null
);

COMMENT ON TABLE shop.producers IS 'List of producers for products'; 