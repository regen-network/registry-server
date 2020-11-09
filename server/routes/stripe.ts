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
          application_fee_amount: priceObject.unit_amount * units * 0.10,
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
      console.log('try constructEvent')
      event = stripe.webhooks.constructEvent(
        req.body,
        sig,
        process.env.STRIPE_ENDPOINT_SECRET
      );
      if (event) console.log('event')
    } catch (err) {
      res.status(400).send(`Webhook Error: ${err.message}`);
    }

    // try {
    //   console.log('try pgPool')
    //   client = await pgPool.connect();
    //   console.log('client')
    // } catch (err) {
    //   console.error('Error acquiring postgres client', err);
    //   res.sendStatus(500);
    // }

    // Handle the event
    let invoice;
    let lines;
    console.log('reading event type')
    switch (event.type) {
      case 'invoiceitem.created':
      case 'invoiceitem.updated':
      case 'invoiceitem.deleted':
        console.log('invoiceitem');
        const invoiceId = event.data.object.invoice;
        try {
          lines = await stripe.invoices.listLineItems(invoiceId);
          if (lines.data.length > 0) {
            let amount: number = 0;
            // Get connected account id from product
            // Assuming the same connect account_id to be used for all line items
            try {
              const product = await stripe.products.retrieve(lines.data[0].price.product);

              // Get total amount
              for (let i = 0; i < lines.data.length; i++) {
                amount = amount + lines.data[i].amount;
              }

              // Update invoice with connected account id
              if (product.metadata && product.metadata.account_id) {
                try {
                  await stripe.invoices.update(
                    invoiceId,
                    {
                      application_fee_amount: amount * 0.10,
                      transfer_data: {
                        destination: product.metadata.account_id,
                      },
                    },
                  );
                  res.sendStatus(200);
                } catch (err) {
                  console.error('Error updating Stripe invoice', err);
                  res.status(500).end();
                }
              } else {
                res.sendStatus(200);
              }
            } catch (err) {
              console.error('Error getting Stripe product', err);
              res.status(500).end();
            }
          } else {
            // No line items, nothing to do
            res.sendStatus(200);
          }
        } catch (err) {
          console.error('Error getting Stripe invoice line items', err);
          res.sendStatus(500);
        }
        console.log('break');
        break;
      case 'invoice.payment_succeeded':
        invoice = event.data.object;
        lines = invoice.lines.data;

        if (lines.length) {
          item = lines[0]; // TODO loop through all lines
          try {
            const product = await stripe.products.retrieve(item.price.product);
            try {
              // Transfer credits
              // await client.query(
              //   'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11, $12)',
              //   [
              //     product.metadata.vintage_id,
              //     invoice.metadata.wallet_id,
              //     invoice.metadata.home_address_id,
              //     item.quantity,
              //     item.amount / 100 / item.quantity,
              //     'succeeded',
              //     invoice.id,
              //     'stripe_invoice',
              //     item.currency,
              //     invoice['customer_email'],
              //     true,
              //     invoice['customer_name'],
              //   ]
              // );
              res.sendStatus(200);
            } catch (err) {
              res.sendStatus(500);
              console.error('Error transfering credits', err);
            }
          } catch (err) {
            res.sendStatus(500);
            console.error('Error getting Stripe product', err);
          }
        } else {
          res.status(400).end();
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
                // await client.query(
                //   'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11, $12)',
                //   [
                //     product.metadata.vintage_id,
                //     walletId,
                //     addressId,
                //     item.quantity,
                //     item.price.unit_amount / 100,
                //     'succeeded',
                //     session.id,
                //     'stripe_checkout',
                //     item.price.currency,
                //     session['customer_email'],
                //     true,
                //     name,
                //   ]
                // );
                res.sendStatus(200);
              } catch (err) {
                res.sendStatus(500);
                console.error('Error transfering credits', err);
              }
            } catch (err) {
              res.sendStatus(500);
              console.error('Error getting Stripe product', err);
            }
          }
        } catch (err) {
          res.sendStatus(500);
          console.error('Error getting Stripe session line items', err);
        // } finally {
          // client.release();
        }
        break;
      default:
        // Unexpected event type
        return res.status(400).end();
    }
  }
);

module.exports = router;
