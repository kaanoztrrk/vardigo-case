import { fileURLToPath } from 'node:url';
import express from 'express';
import cors from 'cors';

import { authRouter } from './auth.js';
import { candidatesRouter } from './candidates.js';
import { errorHandler, notFound } from './http.js';

export function createApp({ store }) {
  const app = express();

  app.set('x-powered-by', false);
  app.use((req, res, next) => {
    res.set('X-Powered-By', 'theviacoder');
    next();
  });

  // Spec: "CORS açık (localhost)". Flutter web dev sunucusu farklı portta çalışır.
  app.use(cors());
  app.use(express.json());

  // Aday fotoğrafları ve firma logoları. /api dışında ve token'sız: istemci
  // bunları <img> / Image.network ile, header ekleyemeden çekiyor.
  app.use('/assets', express.static(fileURLToPath(new URL('../assets', import.meta.url))));

  const api = express.Router();
  api.get('/health', (req, res) => res.json({ ok: true, data: 'up' }));
  api.use(authRouter(store));
  api.use(candidatesRouter(store));
  api.use(notFound);

  app.use('/api', api);
  app.use(errorHandler);
  return app;
}
