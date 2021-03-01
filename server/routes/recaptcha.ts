import * as express from 'express';
const axios = require('axios')
import * as bodyParser from 'body-parser';

const router = express.Router();
const recaptchaKey = process.env.RECAPTCHA_SECRET_KEY;

router.post('/recaptcha/verify', bodyParser.json(), async (request, response: express.Response) => {
  const body = request.body;

  axios
    .post(`https://www.google.com/recaptcha/api/siteverify?secret=${recaptchaKey}&response=${body.userResponse}`, {
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
      },
    })
    .then(res => {
      response.send(res.data);
    })
    .catch(error => {
      console.error(error)
      response.status(500).send(error);
    })

});

module.exports = router;
