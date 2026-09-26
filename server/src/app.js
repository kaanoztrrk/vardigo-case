import express from 'express';
import cors from 'cors';

import { authRouter } from './auth.js';
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

  const api = express.Router();
  api.get('/health', (req, res) => res.json({ ok: true, data: 'up' }));
  api.use(authRouter(store));
  api.use(notFound);

  app.use('/api', api);
  app.use(errorHandler);
  return app;
}
