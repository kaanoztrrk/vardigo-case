import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';
import cors from 'cors';

import { authRouter } from './auth.js';
import { candidatesRouter } from './candidates.js';
import { devRouter } from './dev.js';
import { errorHandler, notFound } from './http.js';
import { offersRouter } from './offers.js';

// `now` lets tests pin the clock for offer expiry.
//
// When `webDir` is set, the prebuilt Flutter web app is served too, so
// `npm start` gives you the API and the app on one port. Tests leave it
// out and only get the API.
export function createApp({ store, now = () => new Date(), webDir }) {
  const app = express();

  app.set('x-powered-by', false);
  app.use((req, res, next) => {
    res.set('X-Powered-By', 'theviacoder');
    next();
  });

  // The Flutter dev server runs on a different port.
  app.use(cors());
  app.use(express.json());

  // Candidate photos and company logos. Kept outside /api and public,
  // since Image.network can't send an auth header.
  app.use('/assets', express.static(fileURLToPath(new URL('../assets', import.meta.url))));

  const api = express.Router();
  api.get('/health', (req, res) => res.json({ ok: true, data: 'up' }));
  api.use(authRouter(store));
  api.use(candidatesRouter(store));
  api.use(offersRouter(store, now));
  api.use(devRouter(store, now));
  api.use(notFound);

  app.use('/api', api);

  if (webDir) {
    app.use(express.static(webDir));
    // SPA fallback: refreshing on /candidates or /offers should load
    // index.html and let the app's router take over. Misses under /api
    // and /assets stay 404 so a broken image doesn't get an HTML page.
    const index = path.join(webDir, 'index.html');
    app.use((req, res, next) => {
      const own = req.path.startsWith('/api/') || req.path.startsWith('/assets/');
      if (req.method !== 'GET' || own) return next();
      return res.sendFile(index);
    });
  }

  app.use(errorHandler);
  return app;
}
