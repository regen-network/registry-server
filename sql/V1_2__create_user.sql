create function public.really_create_user(
  email text,
  name text,
  avatar text
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
    (email, name, avatar, party_id)
  values
    (email, name, avatar, v_party.id)
  returning * into v_user;

  -- Refresh the user
  select *
  into v_user
  from "user"
  where id = v_user.id;

  return v_user;
end;
$$ language plpgsql volatile set search_path to pg_catalog, public, pg_temp;