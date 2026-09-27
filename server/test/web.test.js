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

// Sahte web build'i: yalnızca index.html ve bir dosya.
const webDir = fs.mkdtempSync(path.join(os.tmpdir(), 'vardigo-web-'));
fs.writeFileSync(path.join(webDir, 'index.html'), '<html>uygulama</html>');
fs.writeFileSync(path.join(webDir, 'main.dart.js'), 'console.log(1)');

const app = createApp({ store: createStore({ seed }), webDir });

test('kök adres uygulamayı sunar', async () => {
  const res = await request(app).get('/');
  assert.equal(res.status, 200);
  assert.match(res.text, /uygulama/);
});

test('build dosyaları olduğu gibi sunulur', async () => {
  const res = await request(app).get('/main.dart.js');
  assert.equal(res.status, 200);
  assert.match(res.text, /console\.log/);
});

test('uygulamanın sayfaları yenilenince index.html döner', async () => {
  for (const page of ['/candidates', '/offers']) {
    const res = await request(app).get(page);
    assert.equal(res.status, 200, page);
    assert.match(res.text, /uygulama/, page);
  }
});

test('API yine JSON zarfıyla çalışır, bilinmeyen uç nokta 404 JSON', async () => {
  const health = await request(app).get('/api/health');
  assert.deepEqual(health.body, { ok: true, data: 'up' });

  const missing = await request(app).get('/api/yok');
  assert.equal(missing.status, 404);
  assert.equal(missing.body.error.code, 'NOT_FOUND');
});

test('eksik görsel 404 kalır, yerine sayfa dönmez', async () => {
  const res = await request(app).get('/assets/photos/yok.png');
  assert.equal(res.status, 404);
  assert.doesNotMatch(res.text, /uygulama/);
});

test('webDir verilmezse yalnızca API: kök adres 404', async () => {
  const apiOnly = createApp({ store: createStore({ seed }) });
  const res = await request(apiOnly).get('/');
  assert.equal(res.status, 404);
});
