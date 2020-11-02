import * as express from 'express';
import * as bodyParser from 'body-parser';

const stripe = require('stripe')(process.env.STRIPE_API_KEY);
const { pgPool } = require('../pool');
const router = express.Router();

router.post(
  '/create-checkout-session',
  bodyParser.json(),
  async (req, res) => {
  const { price, units, cancelUrl, successUrl, customerEmail, clientReferenceId } = req.body;

  try {
    // Retrieve product that contains connected account id in its metadata
    const priceObject = await stripe.prices.retrieve(price);
    const product = await stripe.products.retrieve(priceObject.product);
    try {
      // Create a new checkout session
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ['card'],
        customer_email: customerEmail,
        payment_intent_data: {
          on_behalf_of: product.metadata.account_id,
          transfer_data: {
            destination: product.metadata.account_id,
          },
        },
        line_items: [
          {
            price,
            quantity: units,
          },
        ],
        mode: 'payment',
        success_url: successUrl,
        cancel_url: cancelUrl,
        client_reference_id: clientReferenceId,
      });
      res.json({ id: session.id });
    } catch (err) {
      res.status(400).send(`Error creating Stripe checkout session: ${err.message}`);
    }
  } catch (err) {
    res.sendStatus(500);
    console.error('Error getting Stripe product', err);
  }
});

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
              'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11, $12)',
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
                '',
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
        const clientReferenceId = session['client_reference_id']; // buyer name, wallet id and address id
        const { name, walletId, addressId } = JSON.parse(clientReferenceId);

        try {
          const lineItems = await stripe.checkout.sessions.listLineItems(session.id);
          for (let i = 0; i < lineItems.data.length; i++) {
            const item = lineItems.data[i];
            try {
              const product = await stripe.products.retrieve(item.price.product);
              try {
                // Transfer credits
                await client.query(
                  'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11, $12)',
                  [
                    product.metadata.vintage_id,
                    walletId,
                    addressId,
                    item.quantity,
                    item.price.unitAmount / 100,
                    'succeeded',
                    session.id,
                    'stripe_checkout',
                    item.price.currency,
                    session['customer_email'],
                    true,
                    name,
                  ]
                );
                res.sendStatus(200);
              } catch (err) {
                res.sendStatus(500);
                console.error('Error transfering credits', err);
              }
            } catch(err) {
              res.sendStatus(500);
              console.error('Error getting Stripe product', err);
            }
          }
        } catch (err) {
          res.sendStatus(500);
          console.error('Error getting Stripe session line items', err);
        } finally {
          client.release();
        }
        break;
      default:
        // Unexpected event type
        return res.status(400).end();
    }
  }
);

module.exports = router;
