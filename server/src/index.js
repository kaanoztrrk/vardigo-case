import fs from 'node:fs';
import path from 'node:path';
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

// Prebuilt web app (from `npm run build:web`, committed to the repo).
// If it's missing, only the API starts.
const webDir = fileURLToPath(new URL('../public', import.meta.url));
const hasWeb = fs.existsSync(path.join(webDir, 'index.html'));

createApp({ store, webDir: hasWeb ? webDir : undefined }).listen(port, () => {
  if (hasWeb) console.log(`Uygulama: http://localhost:${port}`);
  console.log(`API: http://localhost:${port}/api`);
});
