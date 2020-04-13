create or replace function private.really_create_user(
  email text,
  name text,
  avatar text,
  auth0_sub text
--   password text default null
) returns "user" as $$
declare
  v_user "user";
  v_party party;
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

  -- Insert the new user
  insert into "user"
    (email, name, avatar, auth0_sub, party_id)
  values
    (email, name, avatar, auth0_sub, v_party.id)
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
  sub text
) returns "user" as $$
declare
  v_user_id uuid;
  v_user "user";
begin
  select id
  into v_user_id
  from "user"
  where auth0_sub = sub; -- or email = email?

  -- no user yet with this auth0 sub, create it
  if v_user_id is null then
    select *
    into v_user
    from private.really_create_user(email, name, avatar, sub);
  -- user already exists, update its auth0 sub
  -- else
  --   update "user" set auth0_sub = sub where id = v_user.id;
  --   -- Refresh the user
  --   select *
  --   into v_user
  --   from "user"
  --   where id = v_user.id;
  end if;

  return v_user;
end;
$$ language plpgsql volatile set search_path to pg_catalog, public, pg_temp;
