CREATE TABLE shacl_graph
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "uri" text NOT NULL UNIQUE
);

grant
  select
on shacl_graph to app_user;