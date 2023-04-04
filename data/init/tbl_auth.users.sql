CREATE SEQUENCE users_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

CREATE TABLE auth.users (
    id integer not null default nextval(('users_seq'::text)::regclass) primary key,
    privilege_id  integer not null references auth.privileges(id) default 1,
    active boolean not null default true,
    email varchar not null unique,
    name varchar not null,
    surname varchar not null,
    phone varchar null,
    city varchar null,
    street varchar null,
    house_num varchar null,
    postcode varchar null,
    company_name varchar null,
    nickname varchar null,
    passwordHash varchar null,
    recover_token varchar null,
    recover_token_valid timestamp with time zone null,
    created_at timestamp not null,
    modified_at timestamp not null default now()
);

COMMENT ON TABLE auth.users IS 'List of users';