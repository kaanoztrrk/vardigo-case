import { Router } from 'express';

import { requireRole } from './auth.js';
import { ApiError, ok } from './http.js';

// Brief: "%100 eşleşme = score >= 80". Seed'deki `perfect` alanı yerine
// kural her istekte score'dan hesaplanıyor: iki kaynak ayrışırsa kazanan
// kural olsun.
const PERFECT_SCORE = 80;

// İlk yüklemede listenin başındaki kaç adayın seçili geleceği
// (referansta "1 kişi seçildi" ve Merve seçili).
const SELECTED_HINT = 1;

const byScore = (a, b) => b.score - a.score;

// Eşitlikte score azalan: "En Yakın"da Merve ile Ferhat (ikisi de 4.9 km)
// her istekte aynı sırada gelsin.
const SORTS = {
  recommended: byScore,
  near: (a, b) => a.kmValue - b.kmValue || byScore(a, b),
  rating: (a, b) => Number(b.rating) - Number(a.rating) || byScore(a, b),
};

const TABS = {
  perfect: (c) => c.score >= PERFECT_SCORE,
  similar: (c) => c.score < PERFECT_SCORE,
};

// API'nin dışarı verdiği biçim. kmValue gibi yalnızca sıralamaya yarayan
// seed alanları dışarı sızmıyor; foto yolu statik /assets altına çevriliyor.
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
      // Header'daki (26) / (16): seed'de sabit etiket. Listedeki gerçek
      // adet 4 (spec: "case için yeterli").
      totalPerfect: labels.totalPerfect,
      totalSimilar: labels.totalSimilar,
      selectedHint: SELECTED_HINT,
      candidates: list.map(toResponse),
    });
  });

  return router;
}
