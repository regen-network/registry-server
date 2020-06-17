module.exports = {
  apps: [
    {
      name: "server",
      script: "server/Server.ts",
      interpreter: "server/node_modules/.bin/ts-node",
      watch: ["server/"],
      ignore_watch: ["server/worker/tasks/"],
      watch_options: {
        usePolling: true,
      },
      log: true,
    },
    {
      name: "worker",
      script: "yarn watch",
      cwd: "server/",
      // watch: ["server/worker/tasks"],
      // watch_options: {
      //   usePolling: true,
      // },
      log: true,
    },
    // {
    //   name: "docker-compose",
    //   script: "docker-compose up",
    //   cwd: "server/",
    //   log: true,
    // },
    // {
    //   name: 'web',
    //   script: 'yarn start',
    //   cwd: 'web/',
    //   log: true
    // }
  ],
  deploy: {},
};
