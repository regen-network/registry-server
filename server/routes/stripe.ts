import * as express from 'express';
import * as bodyParser from 'body-parser';
import * as jwks from 'jwks-rsa';
import * as jwt from 'express-jwt';

import { UserRequest } from '../types';
import getJwt from '../middleware/jwt';

const { runnerPromise } = require('../pool');

let runner;
runnerPromise.then((res) => {
  runner = res;
});

const stripe = require('stripe')(process.env.STRIPE_API_KEY);
const { pgPool } = require('../pool');
const router = express.Router();

router.post(
  '/create-account-link',
  bodyParser.json(),
  getJwt(true),
  async (req: UserRequest, res) => {
    try {
      const { email, refreshUrl, returnUrl } = req.body;
      const account = await stripe.accounts.create({
        email,
        type: 'express',
        country: 'AU',
        capabilities: {
          transfers: {
            requested: true,
          },
        },
        tos_acceptance: {
          service_agreement: 'recipient',
        },
      });

      const accountLink = await stripe.accountLinks.create({
        account: account.id,
        refresh_url: refreshUrl,
        return_url: returnUrl,
        type: 'account_onboarding',
      });
      res.json(accountLink);
    } catch (err) {
      res.status(400).send(err);
    }
  }
);

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
        // payment_intent_data: {
        //   application_fee_amount: priceObject.unit_amount * units * 0.10,
        //   transfer_data: {
        //     destination: product.metadata.account_id,
        //   },
        // },
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
    let event, client, item, result, transferResult;

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

      // Handle the event
      let invoice;
      let lines;
      switch (event.type) {
        case 'invoiceitem.created':
        case 'invoiceitem.updated':
        case 'invoiceitem.deleted':
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
          break;
        case 'invoice.payment_succeeded':
          invoice = event.data.object;
          lines = invoice.lines.data;

          try {
            // Retrieve charge balance_transaction for fee details
            const charge = await stripe.charges.retrieve(
              invoice.charge,
              {
                expand: ['balance_transaction'],
              }
            );
            for (let i = 0; i < lines.length; i++) {
              item = lines[i];
              try {
                // Retrieve product for account id
                const product = await stripe.products.retrieve(item.price.product);

                // Transfer 90% to Connect account minus the Stripe fees
                if (product && product.metadata && product.metadata.account_id && charge) {
                  try {
                    const transfer = await stripe.transfers.create({
                      amount: getTransferAmount(charge.amount, charge.balance_transaction.fee),
                      currency: charge.currency,
                      destination: product.metadata.account_id,
                      source_transaction: charge.id,
                    })
                  } catch (err) {
                    console.error('Error transferring', err);
                    res.status(500).end();
                  }
                }

                // Transfer credits
                try {
                  result = await client.query(
                    'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11, $12, $13, $14)',
                    [
                      product.metadata.vintage_id,
                      invoice.metadata.wallet_id,
                      invoice.metadata.home_address_id,
                      item.quantity,
                      item.amount / 100 / item.quantity,
                      'succeeded',
                      invoice.id,
                      'stripe_invoice',
                      item.currency,
                      invoice.customer_email,
                      true,
                      invoice.customer_name,
                      charge.receipt_url,
                      false,
                    ]
                  );
                } catch (err) {
                  console.error('Error transfering credits', err);
                  res.status(500).send(err);
                }
              } catch (err) {
                console.error(err);
                res.status(500).send(err);
              }
            }

            // Send confirmation email
            if (runner) {
              transferResult = result.rows[0].transfer_credits;
              console.log('transferResult', transferResult)
              try {
                await runner.addJob('credits_transfer__send_confirmation', {
                  email: invoice.customer_email,
                  receiptUrl: charge.receipt_url,
                  creditClass: transferResult.creditClass,
                });
                res.sendStatus(200);
              } catch (err) {
                res.status(400).send(err);
              }
            } else {
              res.sendStatus(200);
            }
          } catch (err) {
            console.error(err);
            res.status(400).send(err);
          }
          break;
        case 'checkout.session.completed':
          const session = event.data.object;
          const clientReferenceId = session['client_reference_id']; // buyer name, wallet id and address id
          const { name, walletId, addressId } = JSON.parse(clientReferenceId);

          try {
            // Retrieve charge balance_transaction for fee details
            const paymentIntent = await stripe.paymentIntents.retrieve(
              session.payment_intent,
              {
                expand: ['charges.data.balance_transaction'],
              }
            );

            if (paymentIntent && paymentIntent.charges && paymentIntent.charges.data.length > 0) {
              const charge = paymentIntent.charges.data[0]; // The data list only contains the latest charge

              const lineItems = await stripe.checkout.sessions.listLineItems(session.id);
              for (let i = 0; i < lineItems.data.length; i++) {
                const item = lineItems.data[i];
                try {
                  const product = await stripe.products.retrieve(item.price.product);

                  // Transfer 90% to Connect account minus the Stripe fees
                  if (product && product.metadata && product.metadata.account_id) {
                    try {
                      const transfer = await stripe.transfers.create({
                        amount: getTransferAmount(charge.amount, charge.balance_transaction.fee),
                        currency: charge.currency,
                        destination: product.metadata.account_id,
                        source_transaction: charge.id,
                      })
                    } catch (err) {
                      console.error('Error transferring', err);
                      res.status(500).end();
                    }
                  }

                  // Transfer credits
                  try {
                    result = await client.query(
                      'SELECT transfer_credits($1, $2, $3, $4, $5, $6, uuid_nil(), $7, $8, $9, $10, $11, $12, $13, $14)',
                      [
                        product.metadata.vintage_id,
                        walletId,
                        addressId,
                        item.quantity,
                        item.price.unit_amount / 100,
                        'succeeded',
                        session.id,
                        'stripe_checkout',
                        item.price.currency,
                        session.customer_email,
                        true,
                        name,
                        charge.receipt_url,
                        false,
                      ]
                    );
                  } catch (err) {
                    console.error('Error transfering credits', err);
                    res.status(500).send(err);
                  }
                } catch (err) {
                  res.status(500).send(err);
                }
              }

              // Send confirmation email
              if (runner) {
                transferResult = result.rows[0].transfer_credits;
                console.log('transferResult', transferResult)
                try {
                  await runner.addJob('credits_transfer__send_confirmation', {
                    email: session.customer_email,
                    receiptUrl: charge.receipt_url,
                    creditClass: transferResult.creditClass,
                  });
                  res.sendStatus(200);
                } catch (err) {
                  res.status(400).send(err);
                }
              } else {
                res.sendStatus(200);
              }

            } else {
              res.status(400).send('No corresponding charge found');
            }
          } catch (err) {
            console.error(err);
            res.status(400).send(err);
          }
          break;
        default:
          // Unexpected event type
          return res.status(400).end();
      }
    } catch (err) {
      console.error('Error acquiring postgres client', err);
      res.sendStatus(500);
    } finally {
      if (client) {
        client.release();
      }
    }
  }
);

function getTransferAmount(amount: number, fee: number): number {
  return amount * 0.9 - fee;
}

module.exports = router;
