# Registry Server

## Prerequisites

Make sure [NodeJS](https://nodejs.org/en/) v8.9.x, [Yarn](https://yarnpkg.com/en/), and [Docker](https://www.docker.com).

[NVM](https://github.com/creationix/nvm) is recommended for managing NodeJS installations and we
are intending to stick to the [LTS](https://github.com/creationix/nvm#long-term-support) releases
of NodeJS for this project.

## Setup

### Starting PostgreSQL Locally

1. Install [docker-compose](https://docs.docker.com/compose/install/)
2. Run `cd server && docker-compose up`

### Environment variables

Based on `.env.example`, create some `.env` file with appropriate values.

## Caching
[Redis](https://redis.io//) is used for caching.
You will need to have Redis running locally. Install and run
```
redis-server
```
then set your REDIS_URL env variable (default is redis://localhost:6379).
TODO: see if we can use Docker for this. See Issue #527

## Starting a development server

1. Install all dependencies with `yarn`
2. Start a development server with `yarn dev`
3. Start coding!!

## Database migrations

[Flyway](https://flywaydb.org) is used to run migrations:
```sh
yarn migrate
```

## Tests

[Jest](https://jestjs.io/) is used for testing:
```sh
yarn test
```

Right now, it's using the development database.
TODO: Use a separate testing database instead and set up new migration command.

## SHACL Graphs

The `schema` folder contains [SHACL](https://www.w3.org/TR/shacl/) graphs for validating data (for example, project related data), using [Turtle](https://www.w3.org/TR/turtle/) or [JSON-LD](https://json-ld.org/).
Eventually, we could move them to their own repo if needed.

These graphs can be stored too in the PostGres database in the `schacl_graph` table.
Some of these graphs will be stored too in the PostGres database in a `schema` table (as JSON-LD using a `jsonb` column) for client-side validation (TBD [regen-network/regen-registry/issues/405](https://github.com/regen-network/regen-registry/issues/405)).



