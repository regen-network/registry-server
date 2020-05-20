alter table "user" alter column address type jsonb using ST_AsGeoJSON(address)::jsonb;
alter table organization alter column address type jsonb using ST_AsGeoJSON(address)::jsonb;
