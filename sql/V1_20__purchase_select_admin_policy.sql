grant select on purchase to app_user;
create policy purchase_select_admin on purchase for select using (
  is_admin()
);
