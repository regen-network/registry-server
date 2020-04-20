module.exports = function() {
  return {
    flywayArgs: {
      url: process.env.FLYWAY_URL || 'jdbc:postgresql:xrn',
      locations: 'filesystem:sql',
      user: process.env.FLYWAY_USER || 'postgres',
      password: process.env.FLYWAY_PASSWORD || '',
    },
  };
};
