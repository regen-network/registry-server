CREATE TYPE project_state AS ENUM
(
  'proposed',
  'pending_approval',
  'active',
  'hold',
  'ended'
);

CREATE TYPE party_type AS ENUM
(
  'user',
  'organization'
);

CREATE TABLE party
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "type" party_type NOT NULL check("type" in ('user', 'organization')),
  "address" geometry,
  "short_description" char(130)
  -- "stripe_token" text
);

grant
  select,
  insert,
  update,
  delete
on party to app_user;

CREATE TABLE wallet
(
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    "addr" bytea NOT NULL
);

grant
  select,
  insert,
  update,
  delete
on wallet to app_user;

CREATE TABLE account_balance
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "credit_vintage_id" uuid,
  "wallet_id" uuid,
  "liquid_balance" integer,
  "burnt_balance" integer
);

grant
  select,
  insert,
  update,
  delete
on account_balance to app_user;

CREATE TABLE "user" (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "type" party_type NOT NULL DEFAULT 'user' check("type" in ('user')),
  "email" text NOT NULL,
  "name" text NOT NULL,
  "avatar" text,
  "wallet_id" uuid,
  "party_id" uuid NOT NULL,
  UNIQUE ("party_id", "type")
);

grant
  select,
  insert,
  update,
  delete
on "user" to app_user;

CREATE TABLE organization (
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "type" party_type NOT NULL DEFAULT 'organization' check("type" in ('organization')),
  "name" text NOT NULL,
  "logo" text,
  "website" text,
  "wallet_id" uuid NOT NULL,
  "party_id" uuid NOT NULL,
  UNIQUE ("party_id", "type")
);

grant
  select,
  insert,
  update,
  delete
on organization to app_user;

CREATE TABLE organization_member (
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "member_id" uuid NOT NULL,
  "organization_id" uuid NOT NULL,
  "is_owner" boolean NOT NULL DEFAULT false
);

grant
  select,
  insert (updated_at, member_id, organization_id, is_owner),
  update (updated_at, member_id, organization_id, is_owner),
  delete
on organization_member to app_user;

CREATE TABLE methodology
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "author_id" uuid NOT NULL
);

grant
  select,
  insert,
  update,
  delete
on methodology to app_user;

CREATE TABLE methodology_version
(
  "id" uuid,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "version" text NOT NULL,
  "date_developed" timestamptz NOT NULL,
  "description" text,
  "boundary" geometry NOT NULL,
  --"_eco_regions" jsonb,
  --"_practices" jsonb,
  --"_outcomes_measured" jsonb,
  "metadata" jsonb,
  "files" jsonb,
  PRIMARY KEY ("id", "created_at")
);

grant
  select,
  insert,
  update,
  delete
on methodology_version to app_user;

CREATE TABLE credit_class
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "designer_id" uuid,
  "methodology_id" uuid NOT NULL
);

grant
  select,
  insert,
  update,
  delete
on credit_class to app_user;

CREATE TABLE credit_class_version
(
  "id" uuid,
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "name" text NOT NULL,
  "version" text NOT NULL,
  "date_developed" timestamptz NOT NULL,
  "description" text,
  "state_machine" jsonb NOT NULL,
  --"_price" jsonb,
  --"_eco_metrics" jsonb,
  "metadata" jsonb,
  PRIMARY KEY ("id", "created_at")
);

grant
  select,
  insert,
  update,
  delete
on credit_class_version to app_user;

CREATE TABLE credit_class_issuer
(
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "credit_class_id" uuid NOT NULL,
  "issuer_id" uuid NOT NULL
);

grant
  select,
  insert,
  update,
  delete
on credit_class_issuer to app_user;

CREATE TABLE credit_vintage
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "credit_class_id" uuid,
  "project_id" uuid,
  "issuer_id" uuid,
  "units" integer,
  "initial_distribution" jsonb
);

grant
  select,
  insert,
  update,
  delete
on credit_vintage to app_user;

CREATE TABLE project
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "developer_id" uuid,
  "steward_id" uuid,
  "land_owner_id" uuid,
  "credit_class_id" uuid NOT NULL,
  "name" text NOT NULL,
  "location" geometry NOT NULL,
  "application_date" timestamptz NOT NULL,
  "start_date" timestamptz NOT NULL,
  "end_date" timestamptz NOT NULL,
  "summary_description" char(160) NOT NULL,
  "long_description" text NOT NULL,
  "photos" text[] NOT NULL,
  "documents" jsonb,
  "area" integer NOT NULL,
  "area_unit" char(10) NOT NULL,
  "state" project_state NOT NULL,
  "last_event_index" integer,
  "impact" jsonb,
  "metadata" jsonb, -- fields_override, presale_url, land_mgmt_actions, key_activities, protected_species
  "registry_id" uuid,
  constraint check_project check
    ("developer_id" is not null or "land_owner_id" is not null or "steward_id" is not null)
);

grant
  select,
  insert,
  update,
  delete
on project to app_user;

CREATE TABLE mrv
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "project_id" uuid
);

grant
  select,
  insert,
  update,
  delete
on mrv to app_user;

CREATE TABLE registry
(
    "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
    "created_at" timestamptz NOT NULL DEFAULT now(),
    "updated_at" timestamptz NOT NULL DEFAULT now(),
    "name" text NOT NULL
);

grant
  select,
  insert,
  update,
  delete
on registry to app_user;

CREATE TABLE event
(
  "id" uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "project_id" uuid NOT NULL,
  "date" timestamptz,
  "summary" char(160) NOT NULL,
  "description" text,
  "from_state" project_state,
  "to_state" project_state
);

grant
  select,
  insert,
  update,
  delete
on event to app_user;

ALTER TABLE account_balance ADD FOREIGN KEY ("credit_vintage_id") REFERENCES credit_vintage ("id");

ALTER TABLE account_balance ADD FOREIGN KEY ("wallet_id") REFERENCES wallet ("id");

--ALTER TABLE user ADD FOREIGN KEY ("type") REFERENCES party ("type");

ALTER TABLE "user" ADD
FOREIGN KEY
("party_id") REFERENCES party
("id");

ALTER TABLE "user" ADD FOREIGN KEY ("wallet_id") REFERENCES wallet ("id");

ALTER TABLE organization ADD FOREIGN KEY ("party_id") REFERENCES party ("id");

ALTER TABLE organization ADD FOREIGN KEY ("wallet_id") REFERENCES wallet ("id");

ALTER TABLE organization_member ADD FOREIGN KEY ("member_id") REFERENCES "user" ("id");

ALTER TABLE organization_member ADD FOREIGN KEY ("organization_id") REFERENCES organization ("id");

ALTER TABLE methodology ADD FOREIGN KEY ("author_id") REFERENCES party ("id");

ALTER TABLE methodology_version ADD FOREIGN KEY ("id") REFERENCES methodology ("id");

ALTER TABLE credit_class ADD FOREIGN KEY ("designer_id") REFERENCES party ("id");

ALTER TABLE credit_class ADD FOREIGN KEY ("methodology_id") REFERENCES methodology ("id");

ALTER TABLE credit_class_version ADD FOREIGN KEY ("id") REFERENCES credit_class ("id");

ALTER TABLE credit_class_issuer ADD FOREIGN KEY ("credit_class_id") REFERENCES credit_class ("id");

ALTER TABLE credit_class_issuer ADD FOREIGN KEY ("issuer_id") REFERENCES wallet ("id");

ALTER TABLE credit_vintage ADD FOREIGN KEY ("credit_class_id") REFERENCES credit_class ("id");

ALTER TABLE credit_vintage ADD FOREIGN KEY ("project_id") REFERENCES project ("id");

ALTER TABLE credit_vintage ADD FOREIGN KEY ("issuer_id") REFERENCES wallet ("id");

ALTER TABLE project ADD FOREIGN KEY ("developer_id") REFERENCES party ("id");

ALTER TABLE project ADD FOREIGN KEY ("steward_id") REFERENCES party ("id");

ALTER TABLE project ADD FOREIGN KEY ("land_owner_id") REFERENCES party ("id");

ALTER TABLE project ADD FOREIGN KEY ("credit_class_id") REFERENCES credit_class ("id");

ALTER TABLE project ADD FOREIGN KEY ("registry_id") REFERENCES registry ("id");

ALTER TABLE mrv ADD FOREIGN KEY ("project_id") REFERENCES project ("id");

ALTER TABLE event ADD FOREIGN KEY ("project_id") REFERENCES project ("id");

CREATE INDEX ON account_balance
("credit_vintage_id");
CREATE INDEX ON account_balance
("wallet_id");
CREATE INDEX ON credit_class
("designer_id");
CREATE INDEX ON credit_class
("methodology_id");
CREATE INDEX ON credit_class_issuer
("credit_class_id");
CREATE INDEX ON credit_vintage
("credit_class_id");
CREATE INDEX ON project
("credit_class_id");
CREATE INDEX ON credit_class_issuer
("issuer_id");
CREATE INDEX ON credit_vintage
("project_id");
CREATE INDEX ON credit_vintage
("issuer_id");
CREATE INDEX ON event
("project_id");
CREATE INDEX ON methodology
("author_id");
CREATE INDEX ON mrv
("project_id");
CREATE INDEX ON organization
("wallet_id");
CREATE INDEX ON project
("developer_id");
CREATE INDEX ON project
("steward_id");
CREATE INDEX ON project
("land_owner_id");
CREATE INDEX ON "user"
("wallet_id");
CREATE INDEX ON project
("registry_id");

--CREATE UNIQUE INDEX ON party ("id", "type");