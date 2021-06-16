-- Remove projects not null constraints as project data 
-- will now get validated with SHACL instead.
-- We might even want to drop some of these columns at some point
-- and replace the columns data with jsonb data in project.metadata
-- as part of regen-network/regen-registry/84.
alter table project alter column credit_class_id drop not null;
alter table project alter column name drop not null;
alter table project alter column application_date drop not null;
alter table project alter column start_date drop not null;
alter table project alter column end_date drop not null;
alter table project alter column area drop not null;
alter table project alter column area_unit drop not null;
alter table project alter column state drop not null;
alter table project alter column image drop not null;

alter table project drop constraint check_project;

-- Drop projects column that are not actually being used.
alter table project drop column summary_description;
alter table project drop column long_description;
