import { PoolClient } from 'pg';

import { withAdminUserDb, becomeRoot, becomeUser, createProject, User, Party } from '../helpers';
import { issueCredits } from './issue_credits.test';

async function transferCredits(
  client: PoolClient,
  vintageId: string | null,
  buyerWalletId: string | null,
  addressId: string | null,
  units: number | null,
  creditPrice: number | null,
  txState: string | null,
  autoRetire: boolean | null,
) {
  const {
    rows: [row],
  } = await client.query(
    `
      select * from public.transfer_credits(
        $1, $2, $3, $4, $5, $6, uuid_nil(), '', 'offline'::purchase_type, 'USD', '', $7, '', '', false
      )
      `,
    [vintageId, buyerWalletId, addressId, units, creditPrice, txState, autoRetire],
  );
  return row;
}

it('transfers credits', () => 
  withAdminUserDb(async (client, user, party) => {
    const { vintageId, buyerWalletId, addressId, project} = await setup(
      client, 1000, user, party
    );

    const result = await transferCredits(client, vintageId,
      buyerWalletId, addressId, 100, 1, 'succeeded', false
    );

    expect(result).not.toBeNull();
    expect(result.transfer_credits).not.toBeNull();
    expect(result.transfer_credits.purchaseId).not.toBeNull();

    // New purchase created
    const { rows: [purchase] } = await client.query(
      'select * from purchase where id=$1',
      [result.transfer_credits.purchaseId]
    );
    expect(purchase).not.toBeNull();
    expect(purchase.type).toEqual('offline');
    expect(purchase.buyer_wallet_id).toEqual(buyerWalletId);
    expect(purchase.address_id).toEqual(addressId);
    expect(purchase.credit_vintage_id).toEqual(vintageId);

    // Account balances updated
    const { rows: balances } = await client.query(
      'select * from account_balance where credit_vintage_id=$1 ORDER BY liquid_balance DESC',
      [vintageId]
    );

    expect(balances).toHaveLength(3);
    const { rows: devParties } = await client.query(
      'select wallet_id from party where id=$1',
      [project.developer_id]
    );
    expect(devParties).toHaveLength(1);
    expect(devParties[0]).not.toBeNull();
    expect(devParties[0].wallet_id).not.toBeNull();
    expect(balances[0].wallet_id).toEqual(devParties[0].wallet_id);
    expect(parseFloat(balances[0].liquid_balance)).toEqual(540);
    expect(parseFloat(balances[0].burnt_balance)).toEqual(0);

    const { rows: stewardParties } = await client.query(
      'select wallet_id from party where id=$1',
      [project.steward_id]
    );
    expect(stewardParties).toHaveLength(1);
    expect(stewardParties[0]).not.toBeNull();
    expect(stewardParties[0].wallet_id).not.toBeNull();
    expect(balances[1].wallet_id).toEqual(stewardParties[0].wallet_id);
    expect(parseFloat(balances[1].liquid_balance)).toEqual(360);
    expect(parseFloat(balances[1].burnt_balance)).toEqual(0);

    expect(balances[2].wallet_id).toEqual(buyerWalletId);
    expect(parseFloat(balances[2].liquid_balance)).toEqual(100);
    expect(parseFloat(balances[2].burnt_balance)).toEqual(0);
  })
);

it('transfers credits and auto-retires', () => 
  withAdminUserDb(async (client, user, party) => {
    const { vintageId, buyerWalletId, addressId, project} = await setup(
      client, 1000, user, party
    );

    const result = await transferCredits(client, vintageId,
      buyerWalletId, addressId, 100, 1, 'succeeded', true,
    );

    expect(result).not.toBeNull();
    expect(result.transfer_credits).not.toBeNull();
    expect(result.transfer_credits.purchaseId).not.toBeNull();

    // New purchase created
    const { rows: [purchase] } = await client.query(
      'select * from purchase where id=$1',
      [result.transfer_credits.purchaseId]
    );
    expect(purchase).not.toBeNull();
    expect(purchase.type).toEqual('offline');
    expect(purchase.buyer_wallet_id).toEqual(buyerWalletId);
    expect(purchase.address_id).toEqual(addressId);
    expect(purchase.credit_vintage_id).toEqual(vintageId);

    // New retirement created
    const { rows: retirements } = await client.query(
      'select * from retirement where wallet_id=$1 and address_id=$2 and credit_vintage_id=$3 and units=$4',
      [buyerWalletId, addressId, vintageId, 100]
    );
    expect(retirements).toHaveLength(1);

    // Account balances updated
    const { rows: balances } = await client.query(
      'select * from account_balance where credit_vintage_id=$1 ORDER BY liquid_balance DESC',
      [vintageId]
    );

    expect(balances).toHaveLength(3);
    const { rows: devParties } = await client.query(
      'select wallet_id from party where id=$1',
      [project.developer_id]
    );
    expect(devParties).toHaveLength(1);
    expect(devParties[0]).not.toBeNull();
    expect(devParties[0].wallet_id).not.toBeNull();
    expect(balances[0].wallet_id).toEqual(devParties[0].wallet_id);
    expect(parseFloat(balances[0].liquid_balance)).toEqual(540);
    expect(parseFloat(balances[0].burnt_balance)).toEqual(0);

    const { rows: stewardParties } = await client.query(
      'select wallet_id from party where id=$1',
      [project.steward_id]
    );
    expect(stewardParties).toHaveLength(1);
    expect(stewardParties[0]).not.toBeNull();
    expect(stewardParties[0].wallet_id).not.toBeNull();
    expect(balances[1].wallet_id).toEqual(stewardParties[0].wallet_id);
    expect(parseFloat(balances[1].liquid_balance)).toEqual(360);
    expect(parseFloat(balances[1].burnt_balance)).toEqual(0);

    expect(balances[2].wallet_id).toEqual(buyerWalletId);
    expect(parseFloat(balances[2].liquid_balance)).toEqual(0);
    expect(parseFloat(balances[2].burnt_balance)).toEqual(100);
  })
);

it('fails if current user is not an admin', () => 
  withAdminUserDb(async (client, user, party) => {
    const { vintageId, buyerWalletId, addressId, project} = await setup(
      client, 1000, user, party
    );

    await becomeRoot(client);
    await client.query(
      'delete from admin where auth0_sub=$1',
      [user.auth0_sub]
    );

    await becomeUser(client, user.auth0_sub);

    const promise = transferCredits(client, vintageId,
      buyerWalletId, addressId, 1001, 1, 'succeeded', true,
    );
    await expect(promise).rejects.toMatchInlineSnapshot(
      `[error: new row violates row-level security policy for table "transaction"]`
    );
  })
);

it('fails if not enough credits left', () => 
  withAdminUserDb(async (client, user, party) => {
    const { vintageId, buyerWalletId, addressId, project} = await setup(
      client, 1000, user, party
    );

    const promise = transferCredits(client, vintageId,
      buyerWalletId, addressId, 1001, 1, 'succeeded', true,
    );

    await expect(promise).rejects.toMatchInlineSnapshot(
      `[error: Not enough available credits left to transfer]`
    );
    await expect(promise).rejects.toHaveProperty('code', 'DNIED');
  })
);

async function setup(client: PoolClient, units: number, user: User, party: Party) {
    await becomeRoot(client);
    // Create buyer
    const { rows: [buyer] } = await client.query(
      `select * from really_create_user_if_needed('buyer-test@test.com',
      'Buyer Test', null, null, '{"buyer"}', '{"some": "address"}'::jsonb, 'buyer', false)`
    );
    expect(buyer).not.toBeNull();
    expect(buyer.party_id).not.toBeNull();
    const { rows: parties } = await client.query(
      `select wallet_id, address_id from party where id=$1`,
      [buyer.party_id]
    );
    expect(parties).toHaveLength(1);
    const buyerWalletId: string = parties[0].wallet_id;
    const addressId: string = parties[0].address_id;

    // Create project
    const project = await createProject(client, 'project name', party.wallet_id);
    expect(project).not.toBeNull();

    // Issue credits 
    await becomeUser(client, user.auth0_sub);
    const issueResult = await issueCredits(client, project.id, units, { projectDeveloper: 0.6, landSteward: 0.4 });
    expect(issueResult).not.toBeNull();
    expect(issueResult.issue_credits).not.toBeNull();
    const vintageId: string = issueResult.issue_credits.creditVintageId;
    expect(vintageId).not.toBeNull();

    return { vintageId, project, buyerWalletId, addressId };
}