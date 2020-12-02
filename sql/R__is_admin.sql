create or replace function is_admin()
returns boolean as $$
declare
  v_is_admin boolean;
begin
  select exists(
    select 1 from admin
    where auth0_sub = public.get_current_user()
  )
  into v_is_admin;

  return v_is_admin;
end;
$$ language plpgsql strict volatile
set search_path
to pg_catalog, public, pg_temp;