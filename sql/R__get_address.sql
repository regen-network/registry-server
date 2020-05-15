create or replace function get_party_address_id
(
  v_party_id uuid
) returns uuid as $$
declare
  v_party party;
  v_address_id uuid;
begin
  select *
  into v_party
  from party
  where id = v_party_id;

  if v_party.type = 'user' then
    select address_id
    into v_address_id
    from "user"
    where party_id = v_party.id;
  else
    select address_id
    into v_address_id
    from "organization"
    where party_id = v_party.id;
  end if;
  return v_address_id;
end;
$$ language plpgsql strict volatile
set search_path
to pg_catalog, public, pg_temp;

create or replace function party_address_id(party party) returns uuid as $$
  select get_party_address_id(party.id)
$$ language sql STABLE;
