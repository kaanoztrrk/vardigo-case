import { Router } from 'express';

import { ApiError, ok } from './http.js';
import { toResponse } from './offers.js';

// Demo ve değerlendirme için yardımcı uç noktalar. Token istemiyorlar:
// README'deki adımlar tek istekle çalışsın. Gerçek bir üründe bunlar
// yalnızca geliştirme ortamında açık olurdu.
export function devRouter(store, now) {
  const router = Router();

  // Veriyi seed'deki başlangıca döndürür; teklif süreleri yeniden
  // "şimdi + 21 saat 32 dakika" olur.
  router.post('/dev/reset', (req, res) => {
    store.reset();
    return ok(res, { reset: true });
  });

  // Bir teklifin süresini hemen doldurur: "Süresi Dolan" sekmesini ve
  // "Teklifin süresi doldu" hatasını 21 saat beklemeden göstermek için.
  router.post('/dev/expire/:id', (req, res) => {
    const at = now();
    const offer = store.write((db) => {
      const target = db.offers.find((o) => o.id === req.params.id);
      if (target?.status === 'pending') {
        target.expiresAt = at.toISOString();
        target.status = 'expired';
      }
      return target;
    });
    if (!offer) {
      throw new ApiError(404, 'OFFER_NOT_FOUND', 'Talep bulunamadı.');
    }
    return ok(res, toResponse(offer, at));
  });

  return router;
}
