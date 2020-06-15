module.exports = {
  apps: [
    {
      name: "server",
      script: "server/Server.ts",
      interpreter: "server/node_modules/.bin/ts-node",
      watch: ["server/"],
      watch_options: {
        usePolling: true,
      },
      log: true,
      env: {
        NODE_ENV: "development",
      },
      env_production: {
        NODE_ENV: "production",
      }
    },
    {
      name: 'docker-compose',
      script: 'docker-compose up',
      cwd: 'server/',
      log: true
    },
    {
      name: 'web',
      script: 'yarn start',
      cwd: 'web/',
      log: true
    }
  ],
  deploy: {},
};
