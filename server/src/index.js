import fs from 'node:fs';
import { fileURLToPath } from 'node:url';

import { createApp } from './app.js';
import { createStore } from './db/store.js';

const port = Number(process.env.PORT ?? 3000);

const seed = JSON.parse(
  fs.readFileSync(new URL('../data/seed.json', import.meta.url), 'utf8'),
);
const store = createStore({
  seed,
  file: fileURLToPath(new URL('../data/db.json', import.meta.url)),
});

createApp({ store }).listen(port, () => {
  console.log(`API: http://localhost:${port}/api`);
});
