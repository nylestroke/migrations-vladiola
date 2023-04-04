CREATE SEQUENCE reviews_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

CREATE TABLE shop.reviews (
    id integer not null default nextval(('reviews_seq'::text)::regclass) primary key,
    product_id integer not null references shop.products(id),
    opinion integer not null,
    message varchar not null,
    name varchar not null,
    email varchar not null,
    created_at timestamp not null default now()
);

COMMENT ON TABLE shop.reviews IS 'List of reviews for products';