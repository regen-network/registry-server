CREATE OR REPLACE FUNCTION public.get_current_user() RETURNS TEXT AS $$
  SELECT current_user::text;
$$ LANGUAGE SQL STABLE;

alter table account_balance enable row level security;

create policy account_balance_select_admin on account_balance for select using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy account_balance_insert_admin on account_balance for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy account_balance_update_admin on account_balance for update using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));

alter table "user" enable row level security;

create policy user_select_all on "user" for select using (true);
create policy user_update_admin on "user" for update using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));

alter table organization enable row level security;

create policy organization_select_all on organization for select using (true);
create policy organization_update_admin on organization for update using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));

alter table credit_vintage enable row level security;

create policy credit_vintage_select_all on credit_vintage for select using (true);
create policy credit_vintage_insert_admin on credit_vintage for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));

alter table organization_member enable row level security;

create policy organization_member_select_admin on organization_member for select using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy organization_member_insert_admin on organization_member for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy organization_member_update_admin on organization_member for update using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy organization_member_delete_admin on organization_member for delete using (is_owner is false and exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));

alter table project enable row level security;

create policy project_select_all on project for select using (true);
create policy project_insert_admin on project for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy project_update_admin on project for update using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy project_delete_admin on project for delete using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));

alter table event enable row level security;
create policy project_select_all on event for select using (true);
create policy event_insert_admin on project for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy event_update_admin on event for update using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy event_delete_admin on event for delete using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
