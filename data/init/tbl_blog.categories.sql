CREATE SEQUENCE blog_categories_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

CREATE TABLE blog.categories (
    id integer not null default nextval(('blog_categories_seq'::text)::regclass) primary key,
    name varchar not null unique
);

COMMENT ON TABLE blog.categories IS 'List of categories for blog';