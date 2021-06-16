alter table project add column creator_id uuid;
alter table project add foreign key ("creator_id") REFERENCES "user" ("id");
create index on project
("creator_id");
