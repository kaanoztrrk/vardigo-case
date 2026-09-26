import { test } from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { createStore, materializeSeed } from '../src/db/store.js';

const seed = JSON.parse(
  fs.readFileSync(new URL('../data/seed.json', import.meta.url), 'utf8'),
);
const NOW = new Date('2026-09-26T10:00:00.000Z');

function tempFile() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'vardigo-store-'));
  return path.join(dir, 'db.json');
}

test('seed süreleri şimdiye göre hesaplanır, seed değişmez', () => {
  const data = materializeSeed(seed, NOW);

  const garson = data.offers.find((o) => o.id === 'o_garson');
  const komi = data.offers.find((o) => o.id === 'o_komi');
  assert.equal(garson.expiresAt, '2026-09-27T07:32:00.000Z'); // +21s 32dk
  assert.equal(komi.expiresAt, '2026-09-27T04:00:00.000Z'); // +18s
  assert.equal(seed.offers[0].expiresAt, 'USE_NOW_PLUS_21H32M');
});

test('yazma dosyaya kalıcı: yeni store aynı veriyi okur', () => {
  const file = tempFile();
  const store = createStore({ seed, file, now: () => NOW });

  store.write((db) => {
    db.offers[0].status = 'accepted';
  });

  const reopened = createStore({ seed, file, now: () => new Date() });
  assert.equal(reopened.read().offers[0].status, 'accepted');
  assert.equal(reopened.read().offers[0].expiresAt, '2026-09-27T07:32:00.000Z');
});

test('hata fırlatan yazma hiçbir değişiklik bırakmaz', () => {
  const file = tempFile();
  const store = createStore({ seed, file, now: () => NOW });

  assert.throws(() =>
    store.write((db) => {
      db.offers[0].status = 'accepted';
      throw new Error('çakışma');
    }),
  );

  assert.equal(store.read().offers[0].status, 'pending');
  assert.equal(
    createStore({ seed, file }).read().offers[0].status,
    'pending',
  );
});

test('read kopya döner, depoyu değiştirmez', () => {
  const store = createStore({ seed, now: () => NOW });

  store.read().offers[0].status = 'rejected';

  assert.equal(store.read().offers[0].status, 'pending');
});

test('reset seed başlangıcına döner', () => {
  const store = createStore({ seed, now: () => NOW });
  store.write((db) => {
    db.offers = [];
  });

  store.reset();

  assert.equal(store.read().offers.length, 3);
});
