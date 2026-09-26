// Spec'teki cevap zarfı:
//   başarı { "ok": true,  "data": ... }
//   hata   { "ok": false, "error": { "code": "...", "message": "..." } }

// Route'ların fırlattığı, kullanıcıya gösterilebilir hata. Express 5
// async handler'lardaki hataları da errorHandler'a kendisi iletiyor.
//
// `extra` zarftaki error nesnesine eklenir; örn. POST /offers hangi
// id'lerin sorunlu olduğunu { ids: [...] } ile bildiriyor.
export class ApiError extends Error {
  constructor(status, code, message, extra = {}) {
    super(message);
    this.status = status;
    this.code = code;
    this.extra = extra;
  }
}

export function ok(res, data, status = 200) {
  return res.status(status).json({ ok: true, data });
}

function fail(res, status, code, message, extra = {}) {
  return res.status(status).json({ ok: false, error: { code, message, ...extra } });
}

// /api altında eşleşmeyen her istek. Express'in varsayılan HTML 404'ü
// yerine istemci aynı zarfı alsın.
export function notFound(req, res) {
  return fail(res, 404, 'NOT_FOUND', `Böyle bir uç nokta yok: ${req.method} ${req.path}`);
}

// Express hata middleware'i 4 parametreyle tanınıyor; next kullanılmasa da
// imzada kalmalı.
export function errorHandler(err, req, res, next) {
  if (err instanceof ApiError) {
    return fail(res, err.status, err.code, err.message, err.extra);
  }
  // express.json() bozuk gövdeyi bu tiple fırlatıyor.
  if (err.type === 'entity.parse.failed') {
    return fail(res, 400, 'INVALID_JSON', 'İstek gövdesi geçerli bir JSON değil.');
  }
  console.error(err);
  return fail(res, 500, 'INTERNAL', 'Beklenmeyen bir hata oluştu.');
}
