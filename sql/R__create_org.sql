create or replace function public.really_create_organization_if_needed
(
  org_name text,
  wallet_addr bytea,
  owner_id uuid,
  roles text[] default null,
  org_address jsonb default null
) returns organization as $$
declare
  v_org party;
  v_party party;
  v_wallet wallet;
  v_address address;
begin
  select *
  from party
  into v_party
  where name = org_name and type = 'organization';

  if v_party is not null then
    select * from organization into v_org where party_id = v_party.id;
    return v_org;
  else
    select * from public.really_create_organization(org_name, wallet_addr, owner_id, roles, org_address)
    into v_org;
    return v_org;
  end if;
end;
$$ language plpgsql volatile
set search_path
to pg_catalog, public, pg_temp;

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
  v_address address;
begin
  -- Insert the new organization's wallet
  insert into wallet
    (addr)
  values
    (wallet_addr)
  returning * into v_wallet;

  -- Insert the organization's address if not null
  if org_address is not null then
    insert into address
      (feature)
    values
      (org_address)
    returning * into v_address;
  end if;

  -- Insert the new party corresponding to the organization
  insert into party
    (type, name, wallet_id, roles, address_id)
  values
    ('organization', name, v_wallet.id, roles, v_address.id)
  returning * into v_party;

  -- Insert the new organization
  insert into organization
    (party_id)
  values
    (v_party.id)
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
