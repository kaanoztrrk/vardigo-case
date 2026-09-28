import { randomUUID } from 'node:crypto';
import { Router } from 'express';

import { requireRole } from './auth.js';
import { ApiError, ok } from './http.js';

// There's only one job in the case ("Garson — Zarif Cheff Restaurant").
// Each new offer copies these fields so it keeps the job details as they
// were when it was sent.
const JOB = {
  title: 'Garson',
  place: 'Zarif Cheff Restaurant',
  pay: '45.000',
  payValue: 45000,
  logo: 'logos/zarif.svg',
  district: 'Kadıköy',
  when: '16 Ağu · 12:00 - 16:00',
};

// From the spec: expiresAt = now + 21h 32m.
const OFFER_LIFETIME_MS = (21 * 60 + 32) * 60_000;

// Extra fields for "Detayları Gör" (the GET /offers/:id example in the spec).
const DETAIL = { city: 'İstanbul', note: 'Şube: Sinanpaşa Mah.' };

// answered = accepted + rejected
const STATUS_FILTERS = {
  pending: ['pending'],
  answered: ['accepted', 'rejected'],
  expired: ['expired'],
};

const isOverdue = (offer, now) =>
  offer.status === 'pending' && new Date(offer.expiresAt) <= now;

// No background timer: overdue offers get flipped to "expired" whenever
// the data is read or written.
export function expireOverdue(db, now) {
  for (const offer of db.offers) {
    if (isOverdue(offer, now)) offer.status = 'expired';
  }
}

// Persists any expirations first, but skips the write when nothing
// expired so plain GETs don't touch the file.
function readFresh(store, now) {
  const db = store.read();
  if (!db.offers.some((o) => isOverdue(o, now))) return db;
  store.write((draft) => expireOverdue(draft, now));
  return store.read();
}

// Computed from expiresAt on every request, so the countdown moves
// whenever the client refetches.
function remainText(expiresAt, now) {
  const minutes = Math.max(0, Math.floor((new Date(expiresAt) - now) / 60_000));
  return `${Math.floor(minutes / 60)} saat ${minutes % 60} dakika`;
}

// Newest first. Seed offers have no createdAt, so they stay at the bottom
// in their original order (sort is stable).
const newestFirst = (a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? '');

// payValue is there so the client can sort by pay. remain only makes
// sense for pending offers.
export function toResponse(offer, now) {
  return {
    id: offer.id,
    title: offer.title,
    place: offer.place,
    pay: offer.pay,
    payValue: offer.payValue,
    logo: `/assets/${offer.logo}`,
    district: offer.district,
    when: offer.when,
    status: offer.status,
    remain: offer.status === 'pending' ? remainText(offer.expiresAt, now) : null,
    expiresAt: offer.expiresAt,
  };
}

export function offersRouter(store, now) {
  const router = Router();

  // All or nothing: if any id is unknown (404) or already has a pending
  // offer (409), nothing gets written. The error is thrown inside
  // store.write so the draft is dropped. Otherwise the client would have
  // to guess which offers went through.
  router.post('/offers', requireRole(store, 'employer'), (req, res) => {
    const workerIds = req.body?.workerIds;
    if (!Array.isArray(workerIds) || workerIds.some((id) => typeof id !== 'string')) {
      throw new ApiError(400, 'INVALID_BODY', 'workerIds bir id dizisi olmalı.');
    }
    if (workerIds.length === 0) {
      throw new ApiError(400, 'EMPTY_SELECTION', 'En az bir aday seçilmeli.');
    }
    // Dedupe so a double click on the client isn't treated as an error.
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

  // There's a single demo worker account and it sees every offer, both
  // the seeded ones and the ones the employer sends. That way one account
  // is enough to show a sent offer arriving on the worker side.
  router.get('/offers', requireRole(store, 'worker'), (req, res) => {
    const { status } = req.query;
    if (status !== undefined && !STATUS_FILTERS[status]) {
      throw new ApiError(400, 'INVALID_QUERY', 'status "pending", "answered" ya da "expired" olmalı.');
    }

    const at = now();
    const db = readFresh(store, at);
    const offers = db.offers
      .filter((o) => !status || STATUS_FILTERS[status].includes(o.status))
      .sort(newestFirst);

    return ok(res, {
      // "12 talep yanıt bekliyor" is a fixed label from the seed, same as
      // the 26 / 16 on the candidates screen. The real list is shorter.
      pendingCount: db.labels.pendingCountLabel,
      offers: offers.map((o) => toResponse(o, at)),
    });
  });

  router.get('/offers/:id', requireRole(store, 'worker'), (req, res) => {
    const at = now();
    const offer = readFresh(store, at).offers.find((o) => o.id === req.params.id);
    if (!offer) {
      throw new ApiError(404, 'OFFER_NOT_FOUND', 'Talep bulunamadı.');
    }
    return ok(res, { ...toResponse(offer, at), ...DETAIL });
  });

  // Accept / reject. The expiry check and the answer happen in the same
  // write, so an offer that expires in between can't be answered.
  // Errors are thrown after the write on purpose: throwing inside would
  // also throw away the "expired" update.
  const answer = (nextStatus) => (req, res) => {
    const at = now();
    const { offer, answered } = store.write((db) => {
      expireOverdue(db, at);
      const target = db.offers.find((o) => o.id === req.params.id);
      if (target?.status !== 'pending') return { offer: target, answered: false };
      target.status = nextStatus;
      target.answeredAt = at.toISOString();
      return { offer: target, answered: true };
    });

    if (!offer) {
      throw new ApiError(404, 'OFFER_NOT_FOUND', 'Talep bulunamadı.');
    }
    if (!answered && offer.status === 'expired') {
      throw new ApiError(409, 'OFFER_EXPIRED', 'Teklifin süresi doldu.');
    }
    if (!answered) {
      throw new ApiError(409, 'OFFER_STATE', 'Bu talep zaten yanıtlanmış.');
    }
    return ok(res, toResponse(offer, at));
  };

  router.post('/offers/:id/accept', requireRole(store, 'worker'), answer('accepted'));
  router.post('/offers/:id/reject', requireRole(store, 'worker'), answer('rejected'));

  return router;
}
