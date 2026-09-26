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

// "Detayları Gör" için ek bilgi (spec'teki GET /offers/:id örneği). Case'de
// tek şehir ve tek şube var.
const DETAIL = { city: 'İstanbul', note: 'Şube: Sinanpaşa Mah.' };

// Sekmeler (spec: answered = accepted + rejected).
const STATUS_FILTERS = {
  pending: ['pending'],
  answered: ['accepted', 'rejected'],
  expired: ['expired'],
};

const isOverdue = (offer, now) =>
  offer.status === 'pending' && new Date(offer.expiresAt) <= now;

// Süresi geçmiş ama hâlâ "pending" duran teklifleri "expired"a çevirir.
// Ayrı bir zamanlayıcı yok: durum her okuma/yazmada, o anki saate göre
// güncelleniyor (spec: "expiresAt geçmişse status otomatik expired").
export function expireOverdue(db, now) {
  for (const offer of db.offers) {
    if (isOverdue(offer, now)) offer.status = 'expired';
  }
}

// Okuma öncesi: süresi dolan varsa önce onu KALICI olarak işler. Hiçbiri
// dolmadıysa diske yazmadan okur (her GET'te dosya yazılmasın).
function readFresh(store, now) {
  const db = store.read();
  if (!db.offers.some((o) => isOverdue(o, now))) return db;
  store.write((draft) => expireOverdue(draft, now));
  return store.read();
}

// Spec: floor(saat) + " saat " + floor(dakika) + " dakika". Sabit metin
// değil, her istekte expiresAt'ten hesaplanıyor; istemci listeyi
// tazeledikçe geri sayım ilerliyor.
function remainText(expiresAt, now) {
  const minutes = Math.max(0, Math.floor((new Date(expiresAt) - now) / 60_000));
  return `${Math.floor(minutes / 60)} saat ${minutes % 60} dakika`;
}

// "Önerilen" sırası: en yeni teklif üstte. Seed tekliflerinin createdAt'i
// yok; sort kararlı olduğu için kendi aralarında PNG'deki sırada (Garson,
// Barista, Komi) ve en altta kalıyorlar.
const newestFirst = (a, b) => (b.createdAt ?? '').localeCompare(a.createdAt ?? '');

// API'nin dışarı verdiği biçim. payValue, istemcinin "Ücret"e göre
// sıralayabilmesi için; remain yalnızca bekleyen teklifte anlamlı.
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

  // İş arayanın sekmeleri. Case'de tek demo iş arayan hesabı var ve TÜM
  // teklifleri görüyor: seed'dekileri de, işverenin adaylara (w_*)
  // gönderdiklerini de. Böylece "talep gönderince iş arayan listesinde
  // görünüyor" kriteri tek hesapla gösterilebiliyor.
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
      // "12 talep yanıt bekliyor": seed'de sabit etiket (bkz. candidates'teki
      // 26 / 16); listedeki gerçek adet daha az.
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

  // İlgileniyorum (accept) / İlgilenmiyorum (reject).
  //
  // Süre kontrolü ve yanıt TEK write içinde: arada saat dolarsa yanıt
  // yine de yazılmasın. Hatalar write'ın DIŞINDA fırlatılıyor, çünkü
  // içeride fırlatılsaydı "süresi doldu → expired" güncellemesi de çöpe
  // giderdi (bkz. createStore).
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
