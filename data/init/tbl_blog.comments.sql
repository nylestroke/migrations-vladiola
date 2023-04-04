CREATE SEQUENCE comments_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

CREATE TABLE blog.comments (
    id integer not null default nextval(('comments_seq'::text)::regclass) primary key,
    blog_id integer not null references blog.blogs(id),
    comment varchar not null,
    created_by varchar not null,
    created_at timestamp not null default now()
);

COMMENT ON TABLE blog.comments IS 'List of comments for blogs';