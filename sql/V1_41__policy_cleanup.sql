-- Needed for checkout
create policy user_select_all on "user" for
select using (true);

create policy party_select_all on party for
select using (true);

create policy address_select_all on address for
select using (true);


