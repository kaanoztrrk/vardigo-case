import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import request from 'supertest';

import { createApp } from '../src/app.js';
import { createStore } from '../src/db/store.js';

const seed = JSON.parse(
  fs.readFileSync(new URL('../data/seed.json', import.meta.url), 'utf8'),
);
const START = new Date('2026-09-26T10:00:00.000Z');
const HOUR = 3_600_000;

// Her test kendi deposu ve kendi saatiyle başlar; saat test içinden ileri
// sarılabiliyor (clock.advance).
function setup() {
  const clock = {
    at: START,
    advance(ms) {
      this.at = new Date(this.at.getTime() + ms);
    },
  };
  const store = createStore({ seed, now: () => clock.at });
  const app = createApp({ store, now: () => clock.at });
  const as = (token) => ({
    get: (path) => request(app).get(`/api${path}`).set('Authorization', `Bearer ${token}`),
    post: (path, body) =>
      request(app).post(`/api${path}`).set('Authorization', `Bearer ${token}`).send(body),
  });
  return { app, store, clock, worker: as('dev-worker'), employer: as('dev-employer') };
}

const titles = (res) => res.body.data.offers.map((o) => o.title);

test('GET /offers?status=pending: seed teklifleri, biçim ve kalan süre', async () => {
  const { worker } = setup();

  const res = await worker.get('/offers?status=pending');

  assert.equal(res.status, 200);
  assert.equal(res.body.data.pendingCount, 12);
  assert.deepEqual(titles(res), ['Garson', 'Barista', 'Komi']);
  assert.deepEqual(res.body.data.offers[0], {
    id: 'o_garson',
    title: 'Garson',
    place: 'Zarif Cheff Restaurant',
    pay: '45.000',
    payValue: 45000,
    logo: '/assets/logos/zarif.svg',
    district: 'Kadıköy',
    when: '16 Ağu · 12:00 - 16:00',
    status: 'pending',
    remain: '21 saat 32 dakika',
    expiresAt: '2026-09-27T07:32:00.000Z',
  });
  assert.equal(res.body.data.offers[2].remain, '18 saat 0 dakika');
});

test('kalan süre saat ilerledikçe azalır', async () => {
  const { worker, clock } = setup();
  clock.advance(HOUR + 90_000); // 1 saat 1.5 dakika

  const res = await worker.get('/offers?status=pending');

  assert.equal(res.body.data.offers[0].remain, '20 saat 30 dakika');
});

test('işverenin gönderdiği teklif iş arayanda en üstte görünür', async () => {
  const { worker, employer, clock } = setup();
  clock.advance(60_000);
  await employer.post('/offers', { workerIds: ['w_merve'] });

  const res = await worker.get('/offers?status=pending');

  assert.deepEqual(titles(res), ['Garson', 'Garson', 'Barista', 'Komi']);
  assert.notEqual(res.body.data.offers[0].id, 'o_garson');
});

test('accept / reject → Cevaplanan sekmesine geçer, Bekleyen\'den düşer', async () => {
  const { worker } = setup();

  const accepted = await worker.post('/offers/o_garson/accept');
  const rejected = await worker.post('/offers/o_barista/reject');

  assert.equal(accepted.status, 200);
  assert.equal(accepted.body.data.status, 'accepted');
  assert.equal(accepted.body.data.remain, null);
  assert.equal(rejected.body.data.status, 'rejected');
  assert.deepEqual(titles(await worker.get('/offers?status=pending')), ['Komi']);
  assert.deepEqual(titles(await worker.get('/offers?status=answered')), ['Garson', 'Barista']);
});

test('ikinci kez yanıt → 409 OFFER_STATE', async () => {
  const { worker } = setup();
  await worker.post('/offers/o_garson/accept');

  const res = await worker.post('/offers/o_garson/reject');

  assert.equal(res.status, 409);
  assert.equal(res.body.error.code, 'OFFER_STATE');
});

test('süresi dolan teklif: Süresi Dolan sekmesinde, yanıt → 409 OFFER_EXPIRED', async () => {
  const { worker, store, clock } = setup();
  clock.advance(19 * HOUR); // Komi (18 saat) doldu, diğerleri (21s 32dk) değil

  const res = await worker.post('/offers/o_komi/accept');

  assert.equal(res.status, 409);
  assert.equal(res.body.error.code, 'OFFER_EXPIRED');
  assert.equal(res.body.error.message, 'Teklifin süresi doldu.');
  // Hata dönse de "expired" güncellemesi kalıcı yazıldı.
  assert.equal(store.read().offers.find((o) => o.id === 'o_komi').status, 'expired');
  assert.deepEqual(titles(await worker.get('/offers?status=expired')), ['Komi']);
  assert.deepEqual(titles(await worker.get('/offers?status=pending')), ['Garson', 'Barista']);
});

test('GET /offers/:id detay: şehir ve not eklenir; bilinmeyen id 404', async () => {
  const { worker } = setup();

  const res = await worker.get('/offers/o_barista');
  assert.equal(res.status, 200);
  assert.equal(res.body.data.place, 'Horizon Cafe');
  assert.equal(res.body.data.city, 'İstanbul');
  assert.equal(res.body.data.note, 'Şube: Sinanpaşa Mah.');

  for (const path of ['/offers/o_yok', '/offers/o_yok/accept']) {
    const missing = path.endsWith('accept') ? await worker.post(path) : await worker.get(path);
    assert.equal(missing.status, 404, path);
    assert.equal(missing.body.error.code, 'OFFER_NOT_FOUND', path);
  }
});

test('geçersiz status → 400; işveren teklif listesini göremez → 401', async () => {
  const { worker, employer } = setup();

  const bad = await worker.get('/offers?status=hepsi');
  assert.equal(bad.status, 400);
  assert.equal(bad.body.error.code, 'INVALID_QUERY');

  for (const res of [await employer.get('/offers'), await employer.post('/offers/o_garson/accept')]) {
    assert.equal(res.status, 401);
    assert.equal(res.body.error.code, 'FORBIDDEN_ROLE');
  }
});

test('dev: expire teklifi hemen doldurur, reset başa döndürür', async () => {
  const { app, worker } = setup();

  const expired = await request(app).post('/api/dev/expire/o_garson');
  assert.equal(expired.status, 200);
  assert.equal(expired.body.data.status, 'expired');
  assert.deepEqual(titles(await worker.get('/offers?status=expired')), ['Garson']);

  const reset = await request(app).post('/api/dev/reset');
  assert.equal(reset.status, 200);
  assert.deepEqual(titles(await worker.get('/offers?status=pending')), ['Garson', 'Barista', 'Komi']);

  const missing = await request(app).post('/api/dev/expire/o_yok');
  assert.equal(missing.status, 404);
});
