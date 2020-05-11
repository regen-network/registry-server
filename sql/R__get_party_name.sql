create or replace function get_party_name
(
  v_party_id uuid
) returns text as $$
declare
  v_party party;
  v_name text;
begin
  select *
  into v_party
  from party
  where id = v_party_id;

  if v_party.type = 'user' then
    select name
    into v_name
    from "user"
    where party_id = v_party.id;
  else
    select name
    into v_name
    from "organization"
    where party_id = v_party.id;
  end if;
  return v_name;
end;
$$ language plpgsql strict volatile
set search_path
to pg_catalog, public, pg_temp;

create or replace function party_name(party party) returns text as $$
  select get_party_name(party.id)
$$ language sql STABLE;
