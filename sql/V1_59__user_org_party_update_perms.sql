create or replace function public.get_current_user_id() returns uuid
  LANGUAGE sql STABLE
  SET search_path TO 'pg_catalog', 'public', 'pg_temp'
  AS $$
  select id from "user" where auth0_sub = public.get_current_user();
$$;

create policy user_self_update on "user" for
update using (auth0_sub = public.get_current_user());

grant update (description, image, name) on party to app_user;
grant update (website, legal_name) on organization to app_user;

create policy user_party_self_update on party
  for update using (
    id in (select party_id from "user" where auth0_sub = public.get_current_user())
  );

create policy owner_update_organization on organization
  for update using (
    exists(
      select 1
      from organization_member
      inner join "user" on organization_member.member_id = "user".id
      where organization_member.organization_id = organization.id
      and member_id = public.get_current_user_id()
      and is_owner is true
    )
  );