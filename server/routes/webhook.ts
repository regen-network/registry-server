import * as express from 'express';
import * as bodyParser from 'body-parser';

const stripe = require('stripe')(process.env.STRIPE_API_KEY);
const { pgPool } = require('../pool');
const router = express.Router();

router.post(
  '/webhook',
  bodyParser.raw({ type: 'application/json' }),
  async (req, res) => {
    const sig = req.headers['stripe-signature'];
    let event, client, item;

    try {
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_ENDPOINT_SECRET
      );
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
              'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11)',
              [
                invoice.metadata.vintage_id,
                invoice.metadata.wallet_id,
                invoice.metadata.home_address_id,
                item.quantity,
                item.amount / 100 / item.quantity,
                'succeeded',
                invoice.id,
                'stripe_invoice',
                item.currency,
                invoice['customer_email'],
                true,
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
                'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11)',
                [
                  product.metadata.vintage_id,
                  walletId,
                  addressId,
                  item.quantity,
                  item.amount / 100,
                  'succeeded',
                  session.id,
                  'stripe_checkout',
                  item.currency,
                  session['customer_email'],
                  true,
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
          } finally {
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
  }
);

module.exports = router;
