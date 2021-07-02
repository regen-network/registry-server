update credit_vintage set initial_distribution = json_build_object(
  'http://regen.network/projectDeveloperDistribution',
  credit_vintage.initial_distribution -> 'projectDeveloper',
  'http://regen.network/landOwnerDistribution',
  credit_vintage.initial_distribution -> 'landOwner',
  'http://regen.network/landStewardDistribution',
  credit_vintage.initial_distribution -> 'landSteward'
);

update credit_vintage set initial_distribution = initial_distribution - 'projectDeveloper' - 'landOwner' - 'landSteward';