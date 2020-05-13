create or replace function public.really_create_user(
  email text,
  name text,
  avatar text,
  auth0_sub text,
  roles text[] default null,
  address jsonb default null,
  wallet_addr bytea default null
) returns "user" as $$
declare
  v_user "user";
  v_party party;
  v_wallet wallet;
begin
  if email is null then
    raise exception 'Email is required' using errcode = 'MODAT';
  end if;

  -- Insert the new party corresponding to the user
  insert into party
    (type)
  values
    ('user')
  returning * into v_party;

  -- Insert the new user's wallet if not null
  if wallet_addr is not null then
    insert into wallet
      (addr)
    values
      (wallet_addr)
    returning * into v_wallet;
  end if;

  -- Insert the new user
  insert into "user"
    (email, name, avatar, auth0_sub, party_id, is_admin, roles, address, wallet_id)
  values
    (email, name, avatar, auth0_sub, v_party.id, email like '%@regen.network', roles, address, v_wallet.id)
  returning * into v_user;

  -- Refresh the user
  select *
  into v_user
  from "user"
  where id = v_user.id;

  return v_user;
end;
$$ language plpgsql volatile set search_path to pg_catalog, public, pg_temp;

create or replace function private.really_create_user_if_needed(
  email text,
  name text,
  avatar text,
  sub text,
  roles text[] default null
) returns "user" as $$
declare
  v_db_user "user";
  v_auth_user_id uuid;
  v_email text;
  v_user "user";
begin
  v_email := email;

  select *
  into v_db_user
  from "user" u
  where u.email = v_email;

  select id
  into v_auth_user_id
  from "user"
  where auth0_sub = sub;

  if v_db_user.id is not null then
    -- if user already exists but has no auth0_sub yet, update its auth0 sub
    -- (eg pre-created users from pilot projects)
    if v_db_user.auth0_sub is null then
      update "user" set auth0_sub = sub
      where id = v_db_user.id
      returning * into v_user;
    else
      v_user := v_db_user;
    end if;
  else
    -- if no user yet with this auth0 sub, create it
    if v_auth_user_id is null then
      select *
      into v_user
      from public.really_create_user(email, name, avatar, sub, roles, null, null);
    end if;
  end if;

  return v_user;
end;
$$ language plpgsql volatile set search_path to pg_catalog, public, pg_temp;
