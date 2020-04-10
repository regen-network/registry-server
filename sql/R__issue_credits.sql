create or replace function issue_credits(
  project_id uuid,
  issuer_party_id uuid,
  units integer,
  initial_distribution jsonb
) returns credit_vintage as $$
declare
  -- v_credit_class_id uuid;
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
  -- if current_user_id() is null then
  --   raise exception 'You must log in to issue credits' using errcode = 'LOGIN';
  -- end if;

  -- find project
  select *
  into v_project
  from project
  where id = project_id;

  if v_project.id is null then
    raise exception 'Project not found' using errcode = 'NTFND';
  end if;

  -- get issuer's wallet id
  select get_party_wallet_id(issuer_party_id)
  into v_issuer_wallet_id;

  -- select *
  -- into v_party
  -- from party
  -- where id = issuer_party_id;

  -- if v_party.type = 'user' then
  --   select wallet_id
  --   into v_issuer_wallet_id
  --   from "user"
  --   where party_id = v_party.id;
  -- else
  --   select wallet_id
  --   into v_issuer_wallet_id
  --   from "organization"
  --   where party_id = v_party.id;
  -- end if;

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
