// Spec'teki "MİNİMUM TEST" senaryosu, birebir ve sırayla:
//
//   1. employer login → GET /candidates → 4 kişi
//   2. Merve + Derya seç → POST /offers
//   3. worker login → GET /offers?status=pending → en az o iki + seed
//   4. accept biri, reject biri
//   5. GET answered → 2 kayıt
//   6. sayfayı yenile → aynı state
//
// Diğer testlerden farkı: uç noktaları tek tek değil, bir kullanıcının
// yapacağı sırayla ve GERÇEK bir db.json dosyası üzerinde deniyor. Token'lar
// da sabit yazılmıyor, login cevabından alınıyor.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import request from 'supertest';

import { createApp } from '../src/app.js';
import { createStore } from '../src/db/store.js';

const seed = JSON.parse(
  fs.readFileSync(new URL('../data/seed.json', import.meta.url), 'utf8'),
);

// Sunucuyu db.json'dan açar; 6. adımda aynı dosyayla ikinci kez açılıyor.
const boot = (file) => createApp({ store: createStore({ seed, file }) });

async function login(app, role) {
  const res = await request(app).post('/api/auth/login').send({ role });
  assert.equal(res.status, 200);
  return res.body.data.token;
}

test('spec minimum test senaryosu', async (t) => {
  const file = path.join(fs.mkdtempSync(path.join(os.tmpdir(), 'vardigo-e2e-')), 'db.json');
  let app = boot(file);
  let employer, worker, merveOfferId, deryaOfferId;

  await t.test('1. employer login → GET /candidates → 4 kişi', async () => {
    employer = await login(app, 'employer');
    const res = await request(app)
      .get('/api/candidates')
      .set('Authorization', `Bearer ${employer}`);

    assert.equal(res.status, 200);
    assert.deepEqual(
      res.body.data.candidates.map((c) => c.name),
      ['Merve Y.', 'Ferhat C.', 'Derya A.', 'Ayşe K.'],
    );
  });

  await t.test('2. Merve + Derya seç → POST /offers', async () => {
    const res = await request(app)
      .post('/api/offers')
      .set('Authorization', `Bearer ${employer}`)
      .send({ workerIds: ['w_merve', 'w_derya'] });

    assert.equal(res.status, 201);
    const byWorker = Object.fromEntries(res.body.data.created.map((o) => [o.workerId, o.id]));
    merveOfferId = byWorker.w_merve;
    deryaOfferId = byWorker.w_derya;
    assert.ok(merveOfferId && deryaOfferId);
  });

  await t.test('3. worker login → GET /offers?status=pending → o iki + seed', async () => {
    worker = await login(app, 'worker');
    const res = await request(app)
      .get('/api/offers?status=pending')
      .set('Authorization', `Bearer ${worker}`);

    assert.equal(res.status, 200);
    const ids = res.body.data.offers.map((o) => o.id);
    assert.equal(ids.length, 5);
    assert.ok(ids.includes(merveOfferId) && ids.includes(deryaOfferId));
    assert.ok(['o_garson', 'o_barista', 'o_komi'].every((id) => ids.includes(id)));
  });

  await t.test('4. accept biri, reject biri', async () => {
    const accepted = await request(app)
      .post(`/api/offers/${merveOfferId}/accept`)
      .set('Authorization', `Bearer ${worker}`);
    const rejected = await request(app)
      .post(`/api/offers/${deryaOfferId}/reject`)
      .set('Authorization', `Bearer ${worker}`);

    assert.equal(accepted.status, 200);
    assert.equal(accepted.body.data.status, 'accepted');
    assert.equal(rejected.status, 200);
    assert.equal(rejected.body.data.status, 'rejected');
  });

  // 5. ve 6. adım aynı kontrolü yapıyor: önce aynı sunucuda, sonra
  // yeniden açılmış sunucuda.
  const expectAnswered = async () => {
    const res = await request(app)
      .get('/api/offers?status=answered')
      .set('Authorization', `Bearer ${worker}`);
    assert.equal(res.status, 200);
    assert.deepEqual(
      res.body.data.offers.map((o) => [o.id, o.status]).sort(),
      [[merveOfferId, 'accepted'], [deryaOfferId, 'rejected']].sort(),
    );
  };

  await t.test('5. GET answered → 2 kayıt', expectAnswered);

  await t.test('6. sayfayı yenile → aynı state (sunucu yeniden açılsa bile)', async () => {
    // Sayfa yenilemekten daha zor bir sınav: sunucu tamamen kapanıp aynı
    // db.json'dan yeniden açılıyor. Veri bundan sağ çıkıyorsa yenilemeden
    // de çıkar.
    app = boot(file);
    await expectAnswered();

    const pending = await request(app)
      .get('/api/offers?status=pending')
      .set('Authorization', `Bearer ${worker}`);
    assert.deepEqual(
      pending.body.data.offers.map((o) => o.id),
      ['o_garson', 'o_barista', 'o_komi'],
    );
  });
});
