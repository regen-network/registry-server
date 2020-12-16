-- Drop unrelevant columns
ALTER TABLE credit_vintage drop column credit_class_version_id;
ALTER TABLE credit_vintage drop column credit_class_version_created_at;

-- Associate a project with a certain credit_class_version and methodology_version
ALTER TABLE project add column credit_class_version_id uuid;
ALTER TABLE project add column credit_class_version_created_at timestamptz;

ALTER TABLE project ADD FOREIGN KEY ("credit_class_version_id", "credit_class_version_created_at")
REFERENCES credit_class_version ("id", "created_at");
CREATE INDEX ON project
("credit_class_version_id", "credit_class_version_created_at");

ALTER TABLE project add column methodology_version_id uuid;
ALTER TABLE project add column methodology_version_created_at timestamptz;

ALTER TABLE project ADD FOREIGN KEY ("methodology_version_id", "methodology_version_created_at")
REFERENCES methodology_version ("id", "created_at");
CREATE INDEX ON project
("methodology_version_id", "methodology_version_created_at");

-- Add human-readable ids for methodology and credit_class
ALTER TABLE credit_class add column handle text UNIQUE;
ALTER TABLE methodology add column handle text UNIQUE;
