import path from 'node:path';
import { fileURLToPath } from 'node:url';
import express from 'express';
import cors from 'cors';

import { authRouter } from './auth.js';
import { candidatesRouter } from './candidates.js';
import { devRouter } from './dev.js';
import { errorHandler, notFound } from './http.js';
import { offersRouter } from './offers.js';

// `now` testlerde sabit bir saat vermek için; teklif süreleri ona göre.
//
// `webDir` verilirse hazır Flutter web build'i de buradan sunuluyor
// (`npm start` tek komut: API + uygulama aynı adreste; bkz. index.js).
// Testler vermiyor; o zaman yalnızca API.
export function createApp({ store, now = () => new Date(), webDir }) {
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
  api.use(offersRouter(store, now));
  api.use(devRouter(store, now));
  api.use(notFound);

  app.use('/api', api);

  if (webDir) {
    app.use(express.static(webDir));
    // Uygulamanın kendi sayfaları (/candidates, /offers): sayfa
    // yenilenince sunucuda böyle bir dosya yok, index.html dönüyor ve
    // yönlendirmeyi uygulamanın router'ı yapıyor. /api ve /assets altında
    // bulunamayan istekler 404 kalmalı — eksik bir görsele sayfa dönmesin.
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
