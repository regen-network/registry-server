create or replace function get_party_wallet_id
(
  v_party_id uuid
) returns uuid as $$
declare
  v_party party;
  v_wallet_id uuid;
begin
  select *
  into v_party
  from party
  where id = v_party_id;

  if v_party.type = 'user' then
    select wallet_id
    into v_wallet_id
    from "user"
    where party_id = v_party.id;
  else
    select wallet_id
    into v_wallet_id
    from "organization"
    where party_id = v_party.id;
  end if;
  return v_wallet_id;
end;
$$ language plpgsql strict volatile
set search_path
to pg_catalog, public, pg_temp;
