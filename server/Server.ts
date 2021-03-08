import * as express from 'express';
import * as path from 'path';
import { postgraphile } from 'postgraphile';
import * as PgManyToManyPlugin from '@graphile-contrib/pg-many-to-many';
import * as fileUpload from 'express-fileupload';
import * as cors from 'cors';
import { release } from 'os';
import * as bodyParser from 'body-parser';
import { createProxyMiddleware, Filter, Options, RequestHandler } from 'http-proxy-middleware';
import { expressSharp, FsAdapter, HttpAdapter } from 'express-sharp'
import { S3Adapter } from 'express-sharp'
import { Keyv } from 'keyv'

import { UserIncomingMessage } from './types';
import getJwt from './middleware/jwt';

const url = require('url');

const { pgPool } = require('./pool');

if (process.env.NODE_ENV !== 'production') {
  require('dotenv').config();
}

const REGEN_HOSTNAME_PATTERN = /regen\.network$/;
const WEBSITE_PREVIEW_HOSTNAME_PATTERN = /deploy-preview-\d+--regen-website\.netlify\.app$/;
const REGISTRY_PREVIEW_HOSTNAME_PATTERN = /deploy-preview-\d+--regen-registry\.netlify\.app$/;

const corsOptions = (req, callback) => {
  let options;
  if (req.method == 'GET') console.log('corsOptions req', req)
  if (process.env.NODE_ENV !== 'production') {
    options = { origin: true };
  } else {
    const originURL = req.header('Origin') && url.parse(req.header('Origin'));
    if (originURL && (originURL.hostname.match(REGEN_HOSTNAME_PATTERN) ||
      originURL.hostname.match(WEBSITE_PREVIEW_HOSTNAME_PATTERN) ||
      originURL.hostname.match(REGISTRY_PREVIEW_HOSTNAME_PATTERN))) {
      options = { origin: true }; // reflect (enable) the requested origin in the CORS response
    } else {
      options = { origin: false }; // disable CORS for this request
    }
  }

  callback(null, options) // callback expects two parameters: error and options
}

const app = express();

app.use(fileUpload());
app.use(cors(corsOptions));

app.use(getJwt(false));

app.use('/ledger', createProxyMiddleware({
  target: process.env.LEDGER_TENDERMINT_RPC || 'http://13.59.81.92:26657/',
  pathRewrite: { '^/ledger': '/'},
}));

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


// const bucketName = 'mark-test-regen-1'
// const bucketName = 'regen-registry'
// const adapter = new S3Adapter(bucketName)
//The AWS SDK expects the environment variables AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to be set.

// const cache = new Keyv('redis://', { namespace: 'express-sharp' });

app.use(
  '/image',
  expressSharp({
    // cache,
    imageAdapter: new HttpAdapter({
      prefixUrl: 'https://regen-registry.s3.amazonaws.com',
    }),
    //   imageAdapter: adapter,
  })
)

app.use(require('./routes/mailerlite'));
app.use(require('./routes/contact'));
app.use(require('./routes/buyers-info'));
app.use(require('./routes/stripe'));
app.use(require('./routes/auth'));
app.use(require('./routes/recaptcha'));
// app.use(require('./routes/image'));

const port = process.env.PORT || 5000;

app.listen(port);

console.log('Started server on port ' + port);
console.log('Graphiql UI at http://localhost:' + port + '/graphiql');
