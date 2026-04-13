CREATE TABLE IF NOT EXISTS channels (
    id bigint GENERATED ALWAYS AS IDENTITY,
    name text NOT NULL,
    CONSTRAINT channels_pkey PRIMARY KEY (id),
    CONSTRAINT channels_name_key UNIQUE (name)
);
