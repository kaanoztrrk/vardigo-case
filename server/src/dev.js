import { Router } from 'express';

import { ApiError, ok } from './http.js';
import { toResponse } from './offers.js';

// Helper endpoints for the demo. No token needed so the README steps work
// with a single request. In a real product these would be dev-only.
export function devRouter(store, now) {
  const router = Router();

  // Back to the seed state; offer timers restart at now + 21h 32m.
  router.post('/dev/reset', (req, res) => {
    store.reset();
    return ok(res, { reset: true });
  });

  // Expires an offer right away, so you can see the "Süresi Dolan" tab and
  // the expired error without waiting 21 hours.
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
