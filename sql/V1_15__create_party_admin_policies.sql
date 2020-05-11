grant insert on "user" to app_user;
grant insert on organization to app_user;
grant insert on party to app_user;

create policy user_insert_admin on "user" for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy organization_insert_admin on organization for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy party_insert_admin on party for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
