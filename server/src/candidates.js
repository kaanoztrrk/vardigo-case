import { Router } from 'express';

import { requireRole } from './auth.js';
import { ApiError, ok } from './http.js';

// "%100 eşleşme" means score >= 80. We compute it from score instead of
// trusting the seed's `perfect` field, so the rule wins if they disagree.
const PERFECT_SCORE = 80;

// How many candidates start out selected (the reference shows Merve
// selected and "1 kişi seçildi").
const SELECTED_HINT = 1;

const byScore = (a, b) => b.score - a.score;

// Ties fall back to score so the order stays stable, e.g. Merve and Ferhat
// are both 4.9 km away.
const SORTS = {
  recommended: byScore,
  near: (a, b) => a.kmValue - b.kmValue || byScore(a, b),
  rating: (a, b) => Number(b.rating) - Number(a.rating) || byScore(a, b),
};

const TABS = {
  perfect: (c) => c.score >= PERFECT_SCORE,
  similar: (c) => c.score < PERFECT_SCORE,
};

// Sort-only fields like kmValue stay internal, and the photo path points
// at /assets.
function toResponse(c) {
  return {
    id: c.id,
    name: c.name,
    rating: c.rating,
    attend: c.attend,
    km: c.km,
    photo: `/assets/${c.photo}`,
    online: c.online,
    perfect: c.score >= PERFECT_SCORE,
    score: c.score,
    expectedPay: c.expectedPay,
    payMatch: c.payMatch,
  };
}

export function candidatesRouter(store) {
  const router = Router();

  router.get('/candidates', requireRole(store, 'employer'), (req, res) => {
    const { tab, sort = 'recommended' } = req.query;
    if (tab !== undefined && !TABS[tab]) {
      throw new ApiError(400, 'INVALID_QUERY', 'tab "perfect" ya da "similar" olmalı.');
    }
    if (!SORTS[sort]) {
      throw new ApiError(400, 'INVALID_QUERY', 'sort "recommended", "near" ya da "rating" olmalı.');
    }

    const { candidates, labels } = store.read();
    const list = candidates.filter(tab ? TABS[tab] : () => true).sort(SORTS[sort]);

    return ok(res, {
      // The (26) / (16) in the header are fixed labels from the seed.
      // The actual list has 4 candidates, which the spec says is enough.
      totalPerfect: labels.totalPerfect,
      totalSimilar: labels.totalSimilar,
      selectedHint: SELECTED_HINT,
      candidates: list.map(toResponse),
    });
  });

  return router;
}
