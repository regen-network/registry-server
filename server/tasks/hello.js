module.exports = async (payload, { withPgClient }) => {
  // XXX TEST
  console.log('test hello')
  await withPgClient((pgClient) => pgClient.query("insert into address (feature) values ('{}'::jsonb)"));
};
