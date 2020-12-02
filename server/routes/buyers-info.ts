import * as express from 'express';
import * as bodyParser from 'body-parser';
import * as Airtable from 'airtable';

const { runnerPromise } = require('../pool');

let runner;
runnerPromise.then((res) => {
  runner = res;
});

const router = express.Router();
const airtable = new Airtable({ apiKey: process.env.AIRTABLE_API_KEY });
const airtableBuyersBase = airtable.base(process.env.AIRTABLE_BUYERS_BASE);

router.post('/buyers-info', bodyParser.json(), (req, res: express.Response) => {
  const { email, name, orgName, budget } = req.body;
  airtableBuyersBase(process.env.AIRTABLE_BUYERS_TABLE).create(
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

module.exports = router;
