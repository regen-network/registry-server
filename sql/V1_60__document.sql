CREATE TABLE document
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "type" text NOT NULL,
  "date" timestamptz NOT NULL,
  "url" text NOT NULL,
  "project_id" uuid,
  "event_id" uuid
);

grant
  select
on document to app_user;

ALTER TABLE document ADD FOREIGN KEY ("project_id") REFERENCES project ("id");
ALTER TABLE document ADD FOREIGN KEY ("event_id") REFERENCES event ("id");

CREATE INDEX ON document ("project_id");
CREATE INDEX ON document ("event_id");

ALTER TABLE project DROP COLUMN documents;
