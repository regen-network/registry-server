alter table project drop column location;
alter table project add column address_id uuid;
alter table project add foreign key ("address_id") references address ("id");
create index on project
("address_id");