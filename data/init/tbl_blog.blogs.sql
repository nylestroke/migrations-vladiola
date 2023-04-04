CREATE SEQUENCE blogs_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

CREATE TABLE blog.blogs (
    id integer not null default nextval(('blogs_seq'::text)::regclass) primary key,
    category_id integer not null references blog.categories(id),
    title varchar not null unique,
    description varchar not null,
    short_description varchar not null,
    image varchar not null,
    created_by varchar not null,
    created_at timestamp not null default now()
);

COMMENT ON TABLE blog.blogs IS 'List of blogs';