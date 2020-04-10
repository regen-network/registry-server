alter table project add media text[];
alter table project add image text NOT NULL;
alter table project add map geometry;
alter table project drop photos;

comment
on column project.media is 'List of project video/image urls';
comment
on column project.image is 'Main project image url (presented on project list)';
comment
on column project.map is 'Project GIS data, at least boundary';
