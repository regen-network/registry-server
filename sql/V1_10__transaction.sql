alter table account_balance alter column credit_vintage_id set not null;
alter table account_balance alter column wallet_id set not null;

create type transaction_state as enum
(
  'hold',
  'processing',
  'succeeded',
  'payment_failed',
  'revoked'
);

create table transaction (
  id uuid primary key default uuid_generate_v1(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  broker_id uuid,
  from_wallet_id uuid not null,
  to_wallet_id uuid not null,
  state transaction_state not null,
  units numeric not null,
  credit_price numeric not null,
  credit_vintage_id uuid not null
);

alter table transaction add foreign key ("broker_id") references party ("id");
alter table transaction add foreign key ("from_wallet_id") references wallet ("id");
alter table transaction add foreign key ("to_wallet_id") references wallet ("id");
alter table transaction add foreign key ("credit_vintage_id") references credit_vintage ("id");

create index on transaction ("broker_id");
create index on transaction ("from_wallet_id");
create index on transaction ("to_wallet_id");
create index on transaction ("credit_vintage_id");
