import { withRootDb, reallyCreateOrganization, createUser } from '../helpers';

const walletAddr: string = 'addr123';
const legalName = 'acme inc';
const image: string = 'image';
const description: string = 'description for acme';
const roles = null;
const orgAddress: object = { 'some': 'address' };

it('creates org successfully', () =>
  withRootDb(async (client) => {
    // Action
    const user = await createUser(client, 'test@user.com', 'orgUserName', 'orgImage', null, null)
    const org = await reallyCreateOrganization(
      client,
      legalName,
      walletAddr,
      user.id,
      image,
      description,
      roles,
      orgAddress
    );

    // Assertions
    expect(org).not.toBeNull();
    expect(org.party_id).not.toBeNull();
    expect(org.legal_name).toEqual(legalName);

    const { rows: orgParties } = await client.query(
      'select * from party where id=$1',
      [org.party_id]
    );

    expect(orgParties).toHaveLength(1);
    const orgParty = orgParties[0];

    expect(orgParty.name).toEqual(legalName);
    expect(orgParty.description.trim()).toEqual(description);
    expect(orgParty.image).toEqual(image);
    expect(orgParty.type).toEqual('organization');
    expect(orgParty.wallet_id).not.toBeNull();
    expect(orgParty.address_id).not.toBeNull();

  })
);
