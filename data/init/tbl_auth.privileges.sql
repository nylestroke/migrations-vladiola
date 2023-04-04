CREATE SEQUENCE privileges_seq
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 9223372036854775807
    START 1
    CACHE 1;

CREATE TABLE auth.privileges (
    id integer not null default nextval(('privileges_seq'::text)::regclass) primary key,
    name varchar not null unique
);

COMMENT ON TABLE auth.privileges IS 'List of user privileges';

INSERT INTO auth.privileges (name) VALUES ('CLIENT');
INSERT INTO auth.privileges (name) VALUES ('ADMINISTRATOR');