import express from 'express';
import cors from 'cors';

export function createApp() {
  const app = express();

  // Spec: "CORS açık (localhost)". Flutter web dev sunucusu farklı portta çalışır.
  app.use(cors());
  app.use(express.json());

  const api = express.Router();
  api.get('/health', (req, res) => res.json({ ok: true, data: 'up' }));

  app.use('/api', api);
  return app;
}
