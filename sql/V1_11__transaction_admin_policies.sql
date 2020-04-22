grant
  insert,
  select,
  update
on transaction to app_user;

alter table transaction enable row level security;

create policy transaction_select_admin on transaction for select using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy transaction_insert_admin on transaction for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
create policy transaction_update_admin on transaction for update using (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
