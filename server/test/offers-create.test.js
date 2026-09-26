import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import request from 'supertest';

import { createApp } from '../src/app.js';
import { createStore } from '../src/db/store.js';

const seed = JSON.parse(
  fs.readFileSync(new URL('../data/seed.json', import.meta.url), 'utf8'),
);
const NOW = new Date('2026-09-26T10:00:00.000Z');

// Her test kendi deposuyla başlar: testler birbirinin tekliflerini görmesin.
function setup() {
  const store = createStore({ seed, now: () => NOW });
  const app = createApp({ store, now: () => NOW });
  const send = (body, token = 'dev-employer') =>
    request(app)
      .post('/api/offers')
      .set('Authorization', `Bearer ${token}`)
      .send(body);
  return { store, send };
}

const newOffers = (store) =>
  store.read().offers.filter((o) => o.workerId.startsWith('w_'));

test('Merve + Derya → 201, iki pending teklif yazılır', async () => {
  const { store, send } = setup();

  const res = await send({ workerIds: ['w_merve', 'w_derya'] });

  assert.equal(res.status, 201);
  const created = res.body.data.created;
  assert.deepEqual(created.map((c) => [c.workerId, c.status]), [
    ['w_merve', 'pending'],
    ['w_derya', 'pending'],
  ]);
  assert.ok(created.every((c) => c.id.startsWith('o_')));

  const saved = newOffers(store);
  assert.equal(saved.length, 2);
  assert.equal(saved[0].title, 'Garson');
  assert.equal(saved[0].place, 'Zarif Cheff Restaurant');
  assert.equal(saved[0].createdAt, '2026-09-26T10:00:00.000Z');
  assert.equal(saved[0].expiresAt, '2026-09-27T07:32:00.000Z'); // +21s 32dk
});

test('boş, eksik ya da hatalı workerIds → 400', async () => {
  const { store, send } = setup();

  const cases = [
    [{ workerIds: [] }, 'EMPTY_SELECTION'],
    [{}, 'INVALID_BODY'],
    [{ workerIds: 'w_merve' }, 'INVALID_BODY'],
    [{ workerIds: [42] }, 'INVALID_BODY'],
  ];
  for (const [body, code] of cases) {
    const res = await send(body);
    assert.equal(res.status, 400, JSON.stringify(body));
    assert.equal(res.body.error.code, code, JSON.stringify(body));
  }
  assert.equal(newOffers(store).length, 0);
});

test('bilinmeyen id → 404, bilinen id de YAZILMAZ', async () => {
  const { store, send } = setup();

  const res = await send({ workerIds: ['w_merve', 'w_yok'] });

  assert.equal(res.status, 404);
  assert.equal(res.body.error.code, 'UNKNOWN_WORKER');
  assert.deepEqual(res.body.error.ids, ['w_yok']);
  assert.equal(newOffers(store).length, 0);
});

test('açık teklif varsa → 409, diğer aday da YAZILMAZ (atomik)', async () => {
  const { store, send } = setup();
  await send({ workerIds: ['w_merve'] });

  const res = await send({ workerIds: ['w_derya', 'w_merve'] });

  assert.equal(res.status, 409);
  assert.equal(res.body.error.code, 'OFFER_EXISTS');
  assert.deepEqual(res.body.error.ids, ['w_merve']);
  assert.deepEqual(newOffers(store).map((o) => o.workerId), ['w_merve']);
});

test('süresi dolmuş teklif yeni teklifi engellemez, expired olur', async () => {
  const { store, send } = setup();
  await send({ workerIds: ['w_merve'] });
  store.write((db) => {
    db.offers.find((o) => o.workerId === 'w_merve').expiresAt = '2026-09-26T09:00:00.000Z';
  });

  const res = await send({ workerIds: ['w_merve'] });

  assert.equal(res.status, 201);
  assert.deepEqual(newOffers(store).map((o) => o.status), ['expired', 'pending']);
});

test('aynı id iki kez gelirse tek teklif', async () => {
  const { store, send } = setup();

  const res = await send({ workerIds: ['w_ayse', 'w_ayse'] });

  assert.equal(res.status, 201);
  assert.equal(res.body.data.created.length, 1);
  assert.equal(newOffers(store).length, 1);
});

test('iş arayan teklif gönderemez → 401 FORBIDDEN_ROLE', async () => {
  const { store, send } = setup();

  const res = await send({ workerIds: ['w_merve'] }, 'dev-worker');

  assert.equal(res.status, 401);
  assert.equal(res.body.error.code, 'FORBIDDEN_ROLE');
  assert.equal(newOffers(store).length, 0);
});
