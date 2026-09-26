import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import request from 'supertest';

import { createApp } from '../src/app.js';
import { createStore } from '../src/db/store.js';

const seed = JSON.parse(
  fs.readFileSync(new URL('../data/seed.json', import.meta.url), 'utf8'),
);
const app = createApp({ store: createStore({ seed }) });

const get = (query = '', token = 'dev-employer') =>
  request(app)
    .get(`/api/candidates${query}`)
    .set('Authorization', `Bearer ${token}`);

const ids = (res) => res.body.data.candidates.map((c) => c.id);

test('işveren tüm adayları alır: 4 kişi, sayaçlar seed etiketinden', async () => {
  const res = await get();
  assert.equal(res.status, 200);
  assert.equal(res.body.data.candidates.length, 4);
  assert.equal(res.body.data.totalPerfect, 26);
  assert.equal(res.body.data.totalSimilar, 16);
  assert.equal(res.body.data.selectedHint, 1);
});

test('aday biçimi: foto /assets altında, kmValue sızmıyor', async () => {
  const res = await get();
  const merve = res.body.data.candidates.find((c) => c.id === 'w_merve');
  assert.deepEqual(merve, {
    id: 'w_merve',
    name: 'Merve Y.',
    rating: '4.9',
    attend: '%100 katılım',
    km: '4.9 km',
    photo: '/assets/photos/merve.png',
    online: true,
    perfect: true,
    score: 92,
    expectedPay: '25.000',
    payMatch: true,
  });
});

test('tab: perfect = score >= 80, similar = geri kalan', async () => {
  assert.deepEqual(ids(await get('?tab=perfect')), ['w_merve', 'w_ferhat']);
  assert.deepEqual(ids(await get('?tab=similar')), ['w_derya', 'w_ayse']);
});

test('sort: recommended (varsayılan) / near / rating, eşitlikte score', async () => {
  const recommended = ['w_merve', 'w_ferhat', 'w_derya', 'w_ayse'];
  assert.deepEqual(ids(await get()), recommended);
  assert.deepEqual(ids(await get('?sort=recommended')), recommended);
  // Merve ile Ferhat ikisi de 4.9 km ve 4.9 puan: score (92 > 88) ayırıyor.
  assert.deepEqual(ids(await get('?sort=near')), ['w_ayse', 'w_derya', 'w_merve', 'w_ferhat']);
  assert.deepEqual(ids(await get('?sort=rating')), ['w_merve', 'w_ferhat', 'w_derya', 'w_ayse']);
});

test('geçersiz tab / sort 400 INVALID_QUERY', async () => {
  for (const query of ['?tab=hepsi', '?sort=fiyat']) {
    const res = await get(query);
    assert.equal(res.status, 400, query);
    assert.equal(res.body.error.code, 'INVALID_QUERY', query);
  }
});

test('iş arayan token 401 FORBIDDEN_ROLE', async () => {
  const res = await get('', 'dev-worker');
  assert.equal(res.status, 401);
  assert.equal(res.body.error.code, 'FORBIDDEN_ROLE');
});

test('fotoğraf ve logo token olmadan statik servis ediliyor', async () => {
  const photo = await request(app).get('/assets/photos/merve.png');
  assert.equal(photo.status, 200);
  assert.equal(photo.headers['content-type'], 'image/png');

  const logo = await request(app).get('/assets/logos/zarif.svg');
  assert.equal(logo.status, 200);
  assert.match(logo.headers['content-type'], /image\/svg\+xml/);
});
