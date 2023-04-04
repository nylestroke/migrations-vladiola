CREATE TABLE auth.cfg (
    param varchar not null primary key,
    value varchar not null,
    description varchar not null
);

COMMENT ON TABLE auth.cfg IS 'Auth config';

INSERT INTO auth.cfg (param, value, description) VALUES ('TOKEN_TIMEOUT', '14 days', 'Timeout for token');