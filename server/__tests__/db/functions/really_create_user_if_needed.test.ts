import { withRootDb, createUser } from '../helpers';

const email: string = 'johndoe@gmail.com';
const name: string = 'john doe';
const avatar: string = 'avatar';
const sub = null;
const roles = null;

it('creates user and party successfully', () =>
  withRootDb(async (client) => {
    // Action
    const user = await createUser(client, email, name, avatar, sub, roles);

    // Assertions
    expect(user).not.toBeNull();
    expect(user.auth0_sub).toEqual(sub);
    expect(user.avatar).toEqual(avatar);
    expect(user.email).toEqual(email);

    const { rows: users } = await client.query(
      'select * from "user" where email=$1',
      [email]
    );

    expect(users).toHaveLength(1);
    expect(users[0].auth0_sub).toEqual(sub);
    expect(users[0].avatar).toEqual(avatar);
    expect(users[0].email).toEqual(email);

    const { rows: parties } = await client.query(
      'select * from party where id=$1',
      [user.party_id]
    );

    expect(parties).toHaveLength(1);
    const party = parties[0];

    expect(party.name).toEqual(name);
    expect(party.type).toEqual('user');
    expect(party.roles).toEqual(roles);
    expect(party.wallet_id).not.toBeNull();
  }));

it('returns existing user', () =>
  withRootDb(async (client) => {
    // Action
    await createUser(client, email, name, avatar, sub, roles);
    const user = await createUser(client, email, name, avatar, sub, roles);

    // Assertions
    expect(user).not.toBeNull();
    expect(user.auth0_sub).toEqual(sub);
    expect(user.avatar).toEqual(avatar);
    expect(user.email).toEqual(email);

    const { rows: users } = await client.query(
      'select * from "user" where email=$1',
      [email]
    );

    expect(users).toHaveLength(1);
    expect(users[0].auth0_sub).toEqual(sub);
    expect(users[0].avatar).toEqual(avatar);
    expect(users[0].email).toEqual(email);

    const { rows: parties } = await client.query(
      'select * from party where id=$1',
      [user.party_id]
    );

    expect(parties).toHaveLength(1);
    const party = parties[0];

    expect(party.name).toEqual(name);
    expect(party.type).toEqual('user');
    expect(party.roles).toEqual(roles);
    expect(party.wallet_id).not.toBeNull();
  }));

it('updates existing user auth0 sub', () =>
  withRootDb(async (client) => {
    // Setup
    const newSub = 'newsub';

    // Action
    await createUser(client, email, name, avatar, sub, roles);
    const user = await createUser(client, email, name, avatar, newSub, roles);

    // Assertions
    expect(user).not.toBeNull();
    expect(user.auth0_sub).toEqual(newSub);
    expect(user.avatar).toEqual(avatar);
    expect(user.email).toEqual(email);

    const { rows: users } = await client.query(
      'select * from "user" where email=$1',
      [email]
    );

    expect(users).toHaveLength(1);
  }));

it('fails with null email', () =>
  withRootDb(async (client) => {
    const promise = createUser(client, null, name, avatar, sub, roles);

    await expect(promise).rejects.toMatchInlineSnapshot(
      `[error: Email is required]`
    );
    await expect(promise).rejects.toHaveProperty('code', 'MODAT');
  }));