grant insert on wallet to app_user;

create policy wallet_insert_admin on wallet for insert with check (exists(
  select 1 from "user" where auth0_sub = public.get_current_user() and is_admin is true
));
