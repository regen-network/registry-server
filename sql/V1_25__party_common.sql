alter table party add column name text not null default '';
update party set name = u.name from "user" u where u.party_id = party.id;
update party set name = o.name from organization o where o.party_id = party.id;
alter table "user" drop column name;
alter table organization drop column name;

alter table party add column wallet_id uuid;
alter table party add foreign key ("wallet_id") references wallet ("id");
create index on party
("wallet_id");
update party set wallet_id = u.wallet_id from "user" u where u.party_id = party.id;
update party set wallet_id = o.wallet_id from organization o where o.party_id = party.id;
alter table "user" drop column wallet_id;
alter table organization drop column wallet_id;

alter table party add column address_id uuid;
alter table party add foreign key ("address_id") references address ("id");
create index on party
("address_id");
update party set address_id = u.address_id from "user" u where u.party_id = party.id;
update party set address_id = o.address_id from organization o where o.party_id = party.id;
alter table "user" drop column address_id;
alter table organization drop column address_id;

alter table party add column roles text[];
update party set roles = u.roles from "user" u where u.party_id = party.id;
update party set roles = o.roles from organization o where o.party_id = party.id;
alter table "user" drop column roles;
alter table organization drop column roles;