alter table party enable row level security;

create policy party_select_admin on party for 
select using (
  is_admin()
);

alter table address enable row level security;

alter table "user" enable row level security;

drop policy if exists user_select_all on "user";
create policy user_select_admin on "user" for
select using (
  is_admin()
);


