import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import express from 'express';
import request from 'supertest';

import { createApp } from '../src/app.js';
import { requireRole } from '../src/auth.js';
import { createStore } from '../src/db/store.js';
import { errorHandler, ok } from '../src/http.js';

const seed = JSON.parse(
  fs.readFileSync(new URL('../data/seed.json', import.meta.url), 'utf8'),
);
const store = createStore({ seed });
const app = createApp({ store });

test('login: rol başına sabit token döner', async () => {
  for (const role of ['employer', 'worker']) {
    const res = await request(app).post('/api/auth/login').send({ role });
    assert.equal(res.status, 200);
    assert.deepEqual(res.body, { ok: true, data: { token: `dev-${role}`, role } });
  }
});

test('login: geçersiz ya da eksik rol 400 INVALID_ROLE', async () => {
  for (const body of [{ role: 'admin' }, {}]) {
    const res = await request(app).post('/api/auth/login').send(body);
    assert.equal(res.status, 400);
    assert.equal(res.body.ok, false);
    assert.equal(res.body.error.code, 'INVALID_ROLE');
  }
  // Gövdesiz istek (Content-Type yok)
  const res = await request(app).post('/api/auth/login');
  assert.equal(res.status, 400);
});

test('bozuk JSON gövdesi 400 INVALID_JSON', async () => {
  const res = await request(app)
    .post('/api/auth/login')
    .set('Content-Type', 'application/json')
    .send('{"role":');
  assert.equal(res.status, 400);
  assert.equal(res.body.error.code, 'INVALID_JSON');
});

test('bilinmeyen uç nokta zarf içinde 404 NOT_FOUND', async () => {
  const res = await request(app).get('/api/yok');
  assert.equal(res.status, 404);
  assert.equal(res.body.error.code, 'NOT_FOUND');
});

test('requireRole: token yok / geçersiz / yanlış rol / doğru rol', async () => {
  const guarded = express();
  guarded.get('/x', requireRole(store, 'employer'), (req, res) =>
    ok(res, req.user.id),
  );
  guarded.use(errorHandler);

  const cases = [
    [undefined, 401, 'UNAUTHORIZED'],
    ['Bearer yanlis', 401, 'UNAUTHORIZED'],
    ['dev-employer', 401, 'UNAUTHORIZED'], // "Bearer " öneki yok
    ['Bearer dev-worker', 401, 'FORBIDDEN_ROLE'],
  ];
  for (const [auth, status, code] of cases) {
    const req = request(guarded).get('/x');
    if (auth) req.set('Authorization', auth);
    const res = await req;
    assert.equal(res.status, status, auth);
    assert.equal(res.body.error.code, code, auth);
  }

  const res = await request(guarded)
    .get('/x')
    .set('Authorization', 'Bearer dev-employer');
  assert.equal(res.status, 200);
  assert.equal(res.body.data, 'u_employer');
});
