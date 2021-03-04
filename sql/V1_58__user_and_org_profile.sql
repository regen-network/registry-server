ALTER TABLE "user" ADD column phone_number text;
ALTER TABLE party ADD column description char(160);

UPDATE party SET description = o.description FROM organization o WHERE o.party_id = party.id; -- copy description from organization

ALTER TABLE party ADD column image text DEFAULT '';

ALTER TABLE party ADD constraint check_image check (
  type='organization' and image is not null or type='user'
);

UPDATE party p SET image=u.avatar FROM "user" u
WHERE p.id=u.party_id;

UPDATE organization SET logo='' WHERE logo is null;

UPDATE party p SET image=o.logo FROM organization o
WHERE p.id=o.party_id;

ALTER TABLE organization drop column description; 

ALTER TABLE organization ADD column legal_name text NOT NULL DEFAULT '';
