create or replace function public.really_create_organization(
  name text,
  wallet_addr bytea,
  owner_id uuid,
  roles text[] default null,
  org_address jsonb default null
) returns organization as $$
declare
  v_org organization;
  v_party party;
  v_wallet wallet;
begin
  -- Insert the new party corresponding to the organization
  insert into party
    (type)
  values
    ('organization')
  returning * into v_party;

  -- Insert the new organization's wallet
  insert into wallet
    (addr)
  values
    (wallet_addr)
  returning * into v_wallet;

  -- Insert the new organization
  insert into organization
    (name, wallet_id, party_id, roles, address)
  values
    (name, v_wallet.id, v_party.id, roles, org_address)
  returning * into v_org;

  -- Add first member (owner)
  insert into organization_member
    (member_id, organization_id, is_owner)
  values
    (owner_id, v_org.id, true);

  return v_org;
end;
$$ language plpgsql volatile set search_path
to pg_catalog, public, pg_temp;
