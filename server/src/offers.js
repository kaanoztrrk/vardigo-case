import { randomUUID } from 'node:crypto';
import { Router } from 'express';

import { requireRole } from './auth.js';
import { ApiError, ok } from './http.js';

// Case'de tek iş var (spec: "Garson — Zarif Cheff Restaurant"). Her yeni
// teklif bu işin bilgilerini kopyalar; teklif, gönderildiği andaki iş
// bilgisini taşısın.
const JOB = {
  title: 'Garson',
  place: 'Zarif Cheff Restaurant',
  pay: '45.000',
  payValue: 45000,
  logo: 'logos/zarif.svg',
  district: 'Kadıköy',
  when: '16 Ağu · 12:00 - 16:00',
};

// Spec: expiresAt = now + 21 saat 32 dakika.
const OFFER_LIFETIME_MS = (21 * 60 + 32) * 60_000;

// Süresi geçmiş ama hâlâ "pending" duran teklifleri "expired"a çevirir.
// Ayrı bir zamanlayıcı yok: durum her okuma/yazmada, o anki saate göre
// güncelleniyor (spec: "expiresAt geçmişse status otomatik expired").
export function expireOverdue(db, now) {
  for (const offer of db.offers) {
    if (offer.status === 'pending' && new Date(offer.expiresAt) <= now) {
      offer.status = 'expired';
    }
  }
}

export function offersRouter(store, now) {
  const router = Router();

  // İşveren seçtiği adaylara görüşme talebi gönderir.
  //
  // ATOMİK: bir id bile bilinmiyorsa (404) ya da o adayın açık teklifi
  // varsa (409) HİÇBİR teklif yazılmaz. Hata store.write'ın içinde
  // fırlatıldığı için taslak çöpe gidiyor (bkz. createStore). Yarım
  // yazılmış bir istek, istemcinin "hangileri gitti?" diye tahmin etmesini
  // gerektirirdi.
  router.post('/offers', requireRole(store, 'employer'), (req, res) => {
    const workerIds = req.body?.workerIds;
    if (!Array.isArray(workerIds) || workerIds.some((id) => typeof id !== 'string')) {
      throw new ApiError(400, 'INVALID_BODY', 'workerIds bir id dizisi olmalı.');
    }
    if (workerIds.length === 0) {
      throw new ApiError(400, 'EMPTY_SELECTION', 'En az bir aday seçilmeli.');
    }
    // Aynı id iki kez geldiyse tek teklif: istemcideki çift tıklama hata
    // sayılmasın.
    const ids = [...new Set(workerIds)];

    const created = store.write((db) => {
      const at = now();
      expireOverdue(db, at);

      const known = new Set(db.candidates.map((c) => c.id));
      const unknown = ids.filter((id) => !known.has(id));
      if (unknown.length > 0) {
        throw new ApiError(404, 'UNKNOWN_WORKER', `Aday bulunamadı: ${unknown.join(', ')}`, { ids: unknown });
      }

      const busy = ids.filter((id) =>
        db.offers.some((o) => o.workerId === id && o.status === 'pending'),
      );
      if (busy.length > 0) {
        throw new ApiError(409, 'OFFER_EXISTS', `Bu adaylara zaten bekleyen bir talep var: ${busy.join(', ')}`, { ids: busy });
      }

      const offers = ids.map((workerId) => ({
        id: `o_${randomUUID()}`,
        workerId,
        ...JOB,
        status: 'pending',
        createdAt: at.toISOString(),
        expiresAt: new Date(at.getTime() + OFFER_LIFETIME_MS).toISOString(),
      }));
      db.offers.push(...offers);
      return offers;
    });

    return ok(
      res,
      { created: created.map(({ id, workerId, status }) => ({ id, workerId, status })) },
      201,
    );
  });

  return router;
}
