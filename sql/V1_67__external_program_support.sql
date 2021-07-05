-- Move methodology_version from project to credit_vintage
alter table credit_vintage add column methodology_version_id uuid, add column methodology_version_created_at timestamptz;
alter table credit_vintage add foreign key ("methodology_version_id", "methodology_version_created_at") REFERENCES methodology_version ("id", "created_at");
create index on credit_vintage
("methodology_version_id", "methodology_version_created_at");

-- Same for credit_class_version
alter table credit_vintage add column credit_class_version_id uuid, add column credit_class_version_created_at timestamptz;
alter table credit_vintage add foreign key ("credit_class_version_id", "credit_class_version_created_at") references credit_class_version ("id", "created_at");
create index on credit_vintage
("credit_class_version_id", "credit_class_version_created_at");

-- Move methodology_version and credit_class_version data from project to credit_vintage
update credit_vintage
set credit_class_version_id=p.credit_class_version_id, credit_class_version_created_at=p.credit_class_version_created_at,
  methodology_version_id=p.methodology_version_id, methodology_version_created_at=p.methodology_version_created_at
from project p
where p.id = credit_vintage.project_id;

-- Drop project / credit_vintage columns that are not relevant anymore
alter table project
drop column credit_class_version_id, 
drop column credit_class_version_created_at, 
drop column methodology_version_id,
drop column methodology_version_created_at;

-- credit_vintage metadata can be used to store in the case of 3rd party programs:
-- * serial number
-- * list of supporting docs
-- * additional certifications
-- * initial issuance info: total amount (gross)
-- * link to issuance on 3rd party program website
-- and more generally: amounts allocated to buffer pool / reversal permanence buffer
alter table credit_vintage add column metadata jsonb;

-- Rename issuer_id to tokenizer_id (references a wallet)
-- Add issuer_id to credit_vintage to differenciate initial issuer_id (eg Verra) from the tokenizer (eg RND)
-- issuer_id references a party because it doesn't need to have an on-chain wallet address at this point
-- Also add reseller_id (credits will get issued to the reseller instead of the project stakeholders)
alter table credit_vintage rename issuer_id to tokenizer_id;
alter table credit_vintage add column issuer_id uuid, add column reseller_id uuid;
alter table credit_vintage add foreign key ("issuer_id") references party ("id");
alter table credit_vintage add foreign key ("reseller_id") references wallet ("id");
create index on credit_vintage ("issuer_id");
create index on credit_vintage ("reseller_id");

-- Move buffer pool / permanence reversal buffer data from credit_class_version to credit_vintage
update credit_vintage set metadata = json_build_object(
  'http://regen.network/bufferDistribution',
  json_build_object(
    'http://regen.network/bufferPool',
    credit_class_version.metadata -> 'distribution' -> 'bufferPool',
    'http://regen.network/permanenceReversalBuffer',
    credit_class_version.metadata -> 'distribution' -> 'permanenceReversalBuffer'
  )
)
from credit_class_version
where credit_class_version.id = credit_vintage.credit_class_version_id;

-- Remove distribution key from credit_class_version.metadata
update credit_class_version set metadata = metadata - 'distribution';

-- Other udpates, not necessarily required for now (only relevant for dMRV)
alter table credit_class_version alter column state_machine drop not null;
alter table methodology_version alter column boundary drop not null;

-- Add standard
alter table credit_class add column standard boolean not null default false;
