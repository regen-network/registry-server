create or replace function transfer_credits(
  vintage_id uuid,
  buyer_wallet_id uuid,
  address_id uuid,
  units numeric,
  credit_price numeric,
  tx_state transaction_state,
  broker_id uuid default uuid_nil(),
  stripe_id text default '',
  p_type purchase_type default 'offline'::purchase_type
) returns uuid as $$
declare
  v_user "user";
  v_initial_distribution jsonb;
  v_developer_id uuid;
  v_land_owner_id uuid;
  v_steward_id uuid;
  v_developer_wallet_id uuid;
  v_land_owner_wallet_id uuid;
  v_steward_wallet_id uuid;
  v_available_credits numeric;
  v_key text;
  v_value numeric;
  v_from uuid;
  v_buyer_account_balance account_balance;
  v_purchase_id uuid;
begin
  -- Make sure that current user can transfer credits
  if public.get_current_user() is null then
    raise exception 'You must log in to issue credits' using errcode = 'LOGIN';
  end if;

  -- find user
  select *
  into v_user
  from "user"
  where auth0_sub = public.get_current_user();

  if v_user.id is null then
    raise exception 'User not found' using errcode = 'NTFND';
  end if;

  -- Only admin users allowed to transfer credits for now
  -- XXX Later on, project stakeholders (all of them or only project developer?)
  -- should be able to transfer credits as well
  if v_user.is_admin is false then
    raise exception 'Only admin users can issue credits' using errcode = 'DNIED';
  end if;

  -- get number of available credits left for transfer
  -- (ie credits that are still part of the project stakeholders' liquid balances)
  select * from get_available_credits_record(vintage_id)
  into
    v_available_credits,
    v_initial_distribution,
    v_developer_id,
    v_land_owner_id,
    v_steward_id,
    v_developer_wallet_id,
    v_land_owner_wallet_id,
    v_steward_wallet_id
  as (
    available_credits numeric,
    initial_distribution jsonb,
    developer_id uuid,
    land_owner_id uuid,
    steward_id uuid,
    developer_wallet_id uuid,
    land_owner_wallet_id uuid,
    steward_wallet_id uuid
  );

  if units > v_available_credits then
    raise exception 'Not enough available credits left to transfer' using errcode = 'DNIED';
  end if;

  -- create new purchase
  insert into purchase
    ("stripe_id", type, "buyer_wallet_id", credit_vintage_id, "address_id")
  values
    (stripe_id, p_type, buyer_wallet_id, vintage_id, address_id)
  returning id into v_purchase_id;

  -- update project's stakeholders' account balances and create corresponding transactions
  for v_key, v_value in
  select *
  from jsonb_each_text(v_initial_distribution)
    loop
      if v_value != 0 then
        if v_key = 'projectDeveloper' then
          if v_developer_id is null then
            raise exception 'Project does not have any project developer' using errcode = 'NTFND';
          end if;
          v_from := v_developer_wallet_id;
        end if;

        if v_key = 'landOwner' then
          if v_land_owner_id is null then
            raise exception 'Project does not have any land owner' using errcode = 'NTFND';
          end if;
          v_from := v_land_owner_wallet_id;
        end if;

        if v_key = 'landSteward' then
          if v_steward_id is null then
            raise exception 'Project does not have any land steward' using errcode = 'NTFND';
          end if;
          v_from := v_steward_wallet_id;
        end if;

        update account_balance set liquid_balance = liquid_balance - units * v_value
        where credit_vintage_id = vintage_id and wallet_id = v_from;

        if broker_id = uuid_nil() then
          insert into transaction
            (from_wallet_id, to_wallet_id, state, units, credit_price, credit_vintage_id, purchase_id)
          values
            (v_from, buyer_wallet_id, tx_state, units * v_value, credit_price, vintage_id, v_purchase_id);
        else
          insert into transaction
            (broker_id, from_wallet_id, to_wallet_id, state, units, credit_price, credit_vintage_id, purchase_id)
          values
            (broker_id, v_from, buyer_wallet_id, tx_state, units * v_value, credit_price, vintage_id, v_purchase_id);
        end if;
      end if;
  end loop;

  -- create new account balance for the buyer
  insert into account_balance
    (credit_vintage_id, wallet_id, liquid_balance, burnt_balance)
  values
    (vintage_id, buyer_wallet_id, units, 0)
  on conflict on constraint account_balance_credit_vintage_id_wallet_id_key
  do update set liquid_balance = account_balance.liquid_balance + units
  where account_balance.credit_vintage_id = vintage_id and account_balance.wallet_id = buyer_wallet_id
  returning * into v_buyer_account_balance;

  return v_purchase_id;
end;
$$ language plpgsql strict volatile
set search_path
to pg_catalog, public, pg_temp;
