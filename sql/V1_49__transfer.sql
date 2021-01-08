ALTER TABLE purchase ADD column party_id uuid;
COMMENT ON COLUMN purchase.party_id IS 'id of the party that did the transfer';
ALTER TABLE purchase ADD FOREIGN KEY ("party_id") REFERENCES party ("id");
CREATE INDEX ON purchase
("party_id");

ALTER TABLE purchase ADD column user_id uuid;
COMMENT ON COLUMN purchase.user_id IS 'id of the user that did the transfer on behalf of the party';
ALTER TABLE purchase ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id");
CREATE INDEX ON purchase
("user_id");