grant insert, select on retirement to app_user;

create policy retirement_insert_admin on retirement for
insert with check (
  is_admin()
);

create policy retirement_select_admin on retirement for
select using (
  is_admin()
);