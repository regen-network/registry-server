create or replace function issue_credits(
  project_id uuid,
  units integer,
  initial_distribution jsonb
) returns credit_vintage as $$
declare
  v_issuer "user";
  v_issuer_organization organization;
  v_issuer_wallet_id uuid;
  v_credit_class_issuer_id uuid;
  v_issuee_id uuid;
  v_credit_vintage credit_vintage;
  v_party party;
  v_project project;
  v_key text;
  v_value numeric;
  v_sum numeric;
begin
  if public.get_current_user() is null then
    raise exception 'You must log in to issue credits' using errcode = 'LOGIN';
  end if;

  -- find user
  select *
  into v_issuer
  from "user"
  where auth0_sub = public.get_current_user();

  if v_issuer.id is null then
    raise exception 'User not found' using errcode = 'NTFND';
  end if;

  if v_issuer.is_admin is false then
    raise exception 'Only admin users can issue credits' using errcode = 'DNIED';
  end if;

  -- find org the current user is member of (take first one for now as it always be Regen Network)
  select organization.*
  into v_issuer_organization
  from organization
  inner join organization_member on organization_member.organization_id = organization.id
  where organization_member.member_id = v_issuer.id;

  if v_issuer_organization.party_id is null then
    raise exception 'User should be part of an organization to issue credits in the name of this organization' using errcode = 'DNIED';
  end if;

  -- find project
  select *
  into v_project
  from project
  where id = project_id;

  if v_project.id is null then
    raise exception 'Project not found' using errcode = 'NTFND';
  end if;

  -- get issuer's wallet id
  select get_party_wallet_id(v_issuer_organization.party_id)
  into v_issuer_wallet_id;

  if v_issuer_wallet_id is null then
    raise exception 'Issuer must have a wallet' using errcode = 'NTFND';
  end if;

  -- verify current user is allowed to issue credits for this credit class
  select issuer_id
  into v_credit_class_issuer_id
  from credit_class_issuer
  where credit_class_id = v_project.credit_class_id and issuer_id = v_issuer_wallet_id;

  if v_credit_class_issuer_id is null then
    raise exception 'User not allowed to issue credits for this project' using errcode = 'DNIED';
  end if;

  -- verify sum initial_distribution values = 1
  select sum(jsonb_each_text.value::numeric)
  into v_sum
  from jsonb_each_text(initial_distribution);

  if v_sum != 1 then
    raise exception 'Sum of ownership breakdown not equal to 100' using errcode = 'DNIED';
  end if;

  -- create credit vintage
  insert into credit_vintage
  (credit_class_id, project_id, issuer_id, units, initial_distribution)
  values(v_project.credit_class_id, project_id, v_issuer_wallet_id, units, initial_distribution)
  returning * into v_credit_vintage;

  -- create account balances
  for v_key, v_value IN
  select *
  from jsonb_each_text(initial_distribution)
    loop
      -- raise notice '%: %', v_key, v_value;
      if v_value != 0 then
        if v_key = 'projectDeveloper' then
        if v_project.developer_id is null then
          raise exception 'Project does not have any project developer' using errcode = 'NTFND';
        end if;
        select get_party_wallet_id(v_project.developer_id) into v_issuee_id;
      end if;

      if v_key = 'landOwner' then
        if v_project.land_owner_id is null then
          raise exception 'Project does not have any land owner' using errcode = 'NTFND';
        end if;
        select get_party_wallet_id(v_project.land_owner_id) into v_issuee_id;
      end if;

      if v_key = 'landSteward' then
        if v_project.steward_id is null then
          raise exception 'Project does not have any land steward' using errcode = 'NTFND';
        end if;
        select get_party_wallet_id(v_project.steward_id) into v_issuee_id;
      end if;

      insert into account_balance
        (credit_vintage_id, wallet_id, liquid_balance, burnt_balance)
      values
        (v_credit_vintage.id, v_issuee_id, v_value * units , 0);
      end if;
  end loop;

  return v_credit_vintage;
end;
$$ language plpgsql strict volatile
set search_path
to pg_catalog, public, pg_temp;
