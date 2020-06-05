create or replace function public.create_user_organization_if_needed
(
  email text,
  name text,
  avatar text,
  org_name text,
  wallet_addr bytea,
  roles text[] default null,
  org_address jsonb default null,
  updates boolean default false
) returns organization as $$
declare
  v_user "user";
  v_org organization;
begin
  v_user := public.really_create_user_if_needed
(email, name, null, null, roles, null, name::bytea, updates);
  v_org := public.really_create_organization_if_needed
(org_name, wallet_addr, v_user.id, roles, org_address);

return v_org;
end;
$$ language plpgsql volatile security definer
set search_path
= pg_catalog, public, pg_temp;

create or replace function public.create_user_organization(
  email text,
  name text,
  avatar text,
  org_name text,
  wallet_addr bytea,
  roles text[] default null,
  org_address jsonb default null
) returns organization as $$
declare
  v_user "user";
  v_org organization;
begin
  v_user := public.really_create_user
    (email, name, null, null, roles, null, null);
  v_org := public.really_create_organization
    (org_name, wallet_addr, v_user.id, roles, org_address);

  return v_org;
end;
$$ language plpgsql volatile security definer
set search_path = pg_catalog, public, pg_temp;

create or replace function private.really_create_project(
  methodology_developer_id uuid,
  project_developer_id uuid,
  land_steward_id uuid,
  name text,
  location geometry,
  application_date timestamptz,
  start_date timestamptz,
  end_date timestamptz,
  summary_description char(160),
  long_description text,
  image text,
  area integer,
  area_unit char(10),
  state project_state
) returns project as $$
declare
  v_methodology methodology;
  v_credit_class credit_class;
  v_project project;
begin
  -- Insert new methodology
  insert into methodology
    (author_id)
  values
    (methodology_developer_id)
  returning * into v_methodology;

  -- Insert new credit class with this methodology
  insert into credit_class
    (methodology_id)
  values
    (v_methodology.id)
  returning * into v_credit_class;

  -- Insert new project with this credit class
  insert into project (developer_id, steward_id, credit_class_id, name, location, application_date, start_date, end_date, summary_description, long_description, image, area, area_unit, state)
  values (project_developer_id, land_steward_id, v_credit_class.id, name, location, application_date, start_date, end_date, summary_description, long_description, image, area, area_unit, state)
  returning * into v_project;

  return v_project;
end;
$$ language plpgsql volatile security definer
set search_path = pg_catalog, public, pg_temp;
