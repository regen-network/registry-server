module.exports = async (payload, { withPgClient }) => {
  // XXX TEST
  await withPgClient((pgClient) => pgClient.query("insert into address (feature) values ('{}'::jsonb)"));
};
