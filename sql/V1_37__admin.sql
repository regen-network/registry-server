create table admin
(
  id uuid PRIMARY KEY DEFAULT uuid_generate_v1(),
  auth0_sub text not null
);

alter table retirement enable row level security;

drop policy if exists address_insert_admin on address;
create policy address_insert_all on address for
insert with check (
  true
);




