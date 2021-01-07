create table project_broker
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "project_id" uuid NOT NULL,
  "broker_id" uuid NOT NULL,
  "authorized_by_party_id" uuid NOT NULL,
  "signer_id" uuid NOT NULL
);

ALTER TABLE project_broker ADD FOREIGN KEY ("project_id") REFERENCES project ("id");
CREATE INDEX ON project_broker ("project_id");

ALTER TABLE project_broker ADD FOREIGN KEY ("broker_id") REFERENCES party ("id");
CREATE INDEX ON project_broker ("broker_id");

ALTER TABLE project_broker ADD FOREIGN KEY ("authorized_by_party_id") REFERENCES party ("id");
CREATE INDEX ON project_broker ("authorized_by_party_id");

ALTER TABLE project_broker ADD FOREIGN KEY ("signer_id") REFERENCES "user" ("id");
CREATE INDEX ON project_broker ("signer_id");

grant
  select
on project_broker to app_user;