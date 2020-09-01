import * as express from 'express';
import * as path from 'path';
import * as Airtable from 'airtable';
import { Pool, Client, PoolConfig } from 'pg';
import { postgraphile } from 'postgraphile';
import * as PgManyToManyPlugin from '@graphile-contrib/pg-many-to-many';
import * as jwks from 'jwks-rsa';
import * as jwt from 'express-jwt';
import * as fileUpload from 'express-fileupload';
import * as cors from 'cors';
import { release } from 'os';
import * as bodyParser from 'body-parser';
import { UserRequest, UserIncomingMessage } from './types';
import * as fs from 'fs';

import { main as workerMain } from './worker/worker';

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

const app = express();

const stripe = require('stripe')(process.env.STRIPE_API_KEY);
const airtableBase = new Airtable({ apiKey: process.env.AIRTABLE_API_KEY }).base(process.env.AIRTABLE_BASE);

app.use(fileUpload());
app.use(cors());

app.use(jwt({
  secret: jwks.expressJwtSecret({
    cache: true,
    rateLimit: true,
    jwksRequestsPerMinute: 5,
    jwksUri: 'https://regen-network-registry.auth0.com/.well-known/jwks.json'
  }),
  credentialsRequired: false,
  audience: 'https://regen-registry-server.herokuapp.com/',
  issuer: 'https://regen-network-registry.auth0.com/',
  algorithms: ['RS256']
}));

const pgPoolConfig: PoolConfig = {
  connectionString: process.env.DATABASE_URL || 'postgres://postgres@localhost:5432/xrn',
};

if (process.env.NODE_ENV === 'production') {
  pgPoolConfig.ssl = {
    ca: fs.readFileSync(`${__dirname}/../config/rds-combined-ca-bundle.pem`),
  };
}

const pgPool = new Pool(pgPoolConfig);

let runner;
workerMain(pgPool)
  .then((res) => {
    runner = res;
  })
  .catch((err) => {
  console.error(err);
  process.exit(1);
});

// TODO move to ./routes/
app.post('/buyers-info', bodyParser.json(), (req, res: express.Response) => {
  const { email, name, orgName, budget } = req.body;
  airtableBase(process.env.AIRTABLE_BUYERS_TABLE).create(
    [
      {
        fields: {
          "Full Name": name,
          "Email address": email,
          "Organization Name": orgName,
          Budget: budget,
        },
      },
    ],
    function (err, records) {
      if (err) {
        console.error(err);
        res.status(400).send(err);
      }
      if (runner) {
        runner.addJob('interest_buyers__send_confirmation', { email }).then(() => {
          res.sendStatus(200);
        }, (err) => {
          res.status(400).send(err);
        });
      } else {
        res.sendStatus(200);
      }
    }
  );
});

app.post('/api/login', bodyParser.json(), (req: UserRequest, res: express.Response) => {
  // Create Postgres ROLE for Auth0 user
  if(req.user && req.user.sub) {
    const sub = req.user.sub;
    pgPool.connect((err, client, release) => {
      if (err) {
        res.sendStatus(500);
        console.error('Error acquiring postgres client', err.stack);
      } else {
        client.query('SELECT private.create_app_user_if_needed($1)', [sub], (err, qres) => {
          if (err) {
            res.sendStatus(500);
            console.error('Error creating role', err.stack);
          } else {
            // create user and associated party if needed
            client.query('SELECT private.really_create_user_if_needed($1, $2, $3, $4, NULL)',
              [req.body.email, req.body.nickname, req.body.picture, sub],
              (err, qres) => {
                release();
                if (err) {
                  res.sendStatus(500);
                  console.error('Error creating user', err.stack);
                } else {
                  res.sendStatus(200);
                }
            });
          }
        });
      }
    });
  } else {
    res.sendStatus(200);
  }
});

app.post('/webhook', bodyParser.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'];
  let event, client, item;

  try {
    event = stripe.webhooks.constructEvent(req.body, sig, process.env.STRIPE_ENDPOINT_SECRET);
  } catch (err) {
    res.status(400).send(`Webhook Error: ${err.message}`);
  }

  try {
    client = await pgPool.connect();
  } catch (err) {
    res.sendStatus(500);
    console.error('Error acquiring postgres client', err);
  }

  // Handle the event
  switch (event.type) {
    case 'invoice.payment_succeeded':
      const invoice = event.data.object;
      const lines = invoice.lines.data;

      if (lines.length) {
        item = lines[0];
        try {
          // Transfer credits
          await client.query(
            "SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10)",
            [
              invoice.metadata.vintage_id,
              invoice.metadata.wallet_id,
              invoice.metadata.home_address_id,
              item.quantity,
              (item.amount / 100) / item.quantity,
              "succeeded",
              invoice.id,
              "stripe_invoice",
              item.currency,
              invoice["customer_email"],
            ]
          );
          res.sendStatus(200);
        } catch (err) {
          res.sendStatus(500);
          console.error('Error transfering credits', err);
        }
      } else {
        return res.status(400).end();
      }
      break;
    case 'checkout.session.completed':
      const session = event.data.object;
      const clientReferenceId = session['client_reference_id']; // buyer wallet id and address id

      const items = session['display_items'];
      if (items.length) {
        item = items[0];
        try {
          const product = await stripe.products.retrieve(item.sku.product);
          try {
            const { walletId, addressId } = JSON.parse(clientReferenceId);

            // Transfer credits
            await client.query(
              "SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10)",
              [
                product.metadata.vintage_id,
                walletId,
                addressId,
                item.quantity,
                item.amount / 100,
                "succeeded",
                session.id,
                "stripe_checkout",
                item.currency,
                session["customer_email"],
              ]
            );
            res.sendStatus(200);
          } catch (err) {
            res.sendStatus(500);
            console.error('Error transfering credits', err);
          }
        } catch (err) {
          res.sendStatus(500);
          console.error('Error getting Stripe product', err);
        }
        finally {
          client.release();
        }
      } else {
        return res.status(400).end();
      }
      break;
    default:
      // Unexpected event type
      return res.status(400).end();
  }
});

app.use(postgraphile(pgPool, 'public', {
  graphiql: true,
  watchPg: true,
  dynamicJson: true,
  appendPlugins: [PgManyToManyPlugin],
  pgSettings: (req: UserIncomingMessage) => {
    if(req.user && req.user.sub) {
      const { sub, ...user } = req.user;
      const settings = { role: sub };
      // TODO need to deal with keys that aren't strings properly
      // Object.keys(user).map(k =>
      //   settings['jwt.claims.' + k] = user[k]
      // );
      return settings;
    } else return { role: 'app_user' };
   }
}));

app.use(require('./routes/mailerlite'));

const port = process.env.PORT || 5000;

app.listen(port);

console.log('Started server on port ' + port);
console.log('Graphiql UI at http://localhost:' + port + '/graphiql');
