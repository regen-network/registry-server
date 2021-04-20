drop function if exists public.get_current_user_id;
create or replace function public.get_current_user_id() returns uuid
  LANGUAGE sql STABLE
  SET search_path TO 'pg_catalog', 'public', 'pg_temp'
  AS $$
  select id from "user" where auth0_sub = public.get_current_user();
$$;