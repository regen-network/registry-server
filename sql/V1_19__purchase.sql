create or replace function is_admin()
returns boolean as $$
declare
  v_is_admin boolean;
begin
  select exists(
    select 1 from "user"
    where auth0_sub = public.get_current_user() and is_admin is true
  )
  into v_is_admin;

  return v_is_admin;
end;
$$ language plpgsql strict volatile
set search_path
to pg_catalog, public, pg_temp;

create type purchase_type as enum
(
  'stripe_invoice',
  'stripe_checkout',
  'offline'
);

create table address (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  feature jsonb
);

grant
  insert,
  select
on address to app_user;

create policy address_insert_admin on address for insert with check (
  is_admin()
);
create policy address_select_admin on address for select using (
  is_admin()
);

create table purchase (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  stripe_id text,
  type purchase_type NOT NULL DEFAULT 'offline',
  buyer_wallet_id uuid NOT NULL,
  address_id uuid,
  credit_vintage_id uuid NOT NULL
);

grant
  insert
on purchase to app_user;

create policy purchase_insert_admin on purchase for insert with check (
  is_admin()
);

alter table purchase add foreign key ("buyer_wallet_id") references wallet ("id");
alter table purchase add foreign key ("address_id") references address ("id");
alter table purchase add foreign key ("credit_vintage_id") references credit_vintage ("id");

create index on purchase ("buyer_wallet_id");
create index on purchase ("address_id");
create index on purchase ("credit_vintage_id");

alter table transaction add column purchase_id uuid;
alter table transaction add foreign key ("purchase_id") references purchase ("id");

create index on transaction ("purchase_id");

alter table "user" add column address_id uuid;
alter table "user" add foreign key ("address_id") references address ("id");
create index on "user" ("address_id");

alter table organization add column address_id uuid;
alter table organization add foreign key ("address_id") references address ("id");
create index on organization ("address_id");

alter table "user" drop column address;
alter table organization drop column address;
