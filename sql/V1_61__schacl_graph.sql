CREATE TABLE shacl_graph
(
  "uri" text PRIMARY KEY NOT NULL,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "graph" jsonb NOT NULL
);

grant
  select
on shacl_graph to app_user;