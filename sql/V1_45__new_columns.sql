ALTER TABLE project add column type text;
ALTER TABLE credit_vintage add column credit_class_version_id uuid;
ALTER TABLE credit_vintage add column credit_class_version_created_at timestamptz;
-- alter credit_vintage add column methodology_version_id uuid;

ALTER TABLE credit_vintage ADD FOREIGN KEY ("credit_class_version_id", "credit_class_version_created_at") REFERENCES credit_class_version ("id", "created_at");
CREATE INDEX ON credit_vintage ("credit_class_version_id", "credit_class_version_created_at");
