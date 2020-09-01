create table retirement
(
  "id" uuid primary key DEFAULT uuid_generate_v1(),
  "created_at" timestamptz NOT NULL DEFAULT now(),
  "updated_at" timestamptz NOT NULL DEFAULT now(),
  "wallet_id" uuid NOT NULL,
  "address_id" uuid NOT NULL,
  "credit_vintage_id" uuid NOT NULL,
  "units" numeric NOT NULL
);

ALTER TABLE retirement ADD FOREIGN KEY ("wallet_id") REFERENCES wallet ("id");
ALTER TABLE retirement ADD FOREIGN KEY ("address_id") REFERENCES address ("id");
ALTER TABLE retirement ADD FOREIGN KEY ("credit_vintage_id") REFERENCES credit_vintage ("id");

CREATE INDEX ON retirement
("wallet_id");
CREATE INDEX ON retirement
("address_id");
CREATE INDEX ON retirement
("credit_vintage_id");