alter table credit_vintage add column event_id uuid;
alter table credit_vintage add foreign key ("event_id") references event ("id");
create index on credit_vintage ("event_id");

