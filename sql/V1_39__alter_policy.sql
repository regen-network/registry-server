grant insert on admin to app_user;

alter table admin enable row level security;
create policy admin_select_all on admin for
select using (
  true
);

create policy admin_insert_admin on admin for
insert with check(
  is_admin()
);

alter policy account_balance_select_admin on account_balance using (is_admin());
alter policy account_balance_insert_admin on account_balance with check (is_admin());
alter policy account_balance_update_admin on account_balance using (is_admin());

alter policy user_update_admin on "user" using (is_admin());

alter policy organization_update_admin on organization using (is_admin());

alter policy credit_vintage_insert_admin on credit_vintage with check (is_admin());

alter policy organization_member_select_admin on organization_member using (is_admin());
alter policy organization_member_insert_admin on organization_member with check (is_admin());
alter policy organization_member_update_admin on organization_member using (is_admin());
alter policy organization_member_delete_admin on organization_member using (is_owner
is false and is_admin());

alter policy project_update_admin on project using (is_admin());
alter policy project_insert_admin on project with check (is_admin());
alter policy project_delete_admin on project using (is_admin());

alter policy event_update_admin on event using (is_admin());
drop policy if exists event_insert_admin on project;
create policy event_insert_admin on event with check (is_admin());
alter policy event_delete_admin on event using (is_admin());

alter policy transaction_update_admin on transaction using (is_admin());
alter policy transaction_insert_admin on transaction with check (is_admin());

alter policy user_insert_admin on "user" with check (is_admin());

alter policy organization_insert_admin on organization with check (is_admin());

alter policy party_insert_admin on party with check (is_admin());

alter policy wallet_insert_admin on wallet with check (is_admin());




