drop policy
if exists purchase_select_admin on purchase;

create policy purchase_select_all on purchase for
select using (true);
