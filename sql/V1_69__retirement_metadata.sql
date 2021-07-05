alter table retirement add column metadata jsonb;

create policy retirement_app_user_select on retirement for
select to app_user
using (true);