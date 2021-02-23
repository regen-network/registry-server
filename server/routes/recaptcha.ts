import * as express from 'express';
const https = require('https')
const axios = require('axios')
import * as bodyParser from 'body-parser';

const router = express.Router();

const recaptchaKey = process.env.RECAPTCHA_SECRET_KEY;

router.post('/recaptcha', bodyParser.json(), async (request, response: express.Response) => {
  const body = request.body;
  console.log('***userResponse***',body.userResponse)

  axios
    .post(`https://www.google.com/recaptcha/api/siteverify?secret=${recaptchaKey}&response=${body.userResponse}`, {
      headers: {
        Accept: "application/json",
        "Content-Type": "application/x-www-form-urlencoded; charset=utf-8"
      },
    })
    .then(res => {
      console.log(`##statusCode##: ${res.status}`)
      console.log('##data##:',res.data)
      response.send(res.data);
    })
    .catch(error => {
      console.error(error)
    })

});

module.exports = router;
