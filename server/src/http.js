// Response envelope from the spec:
//   success { "ok": true,  "data": ... }
//   error   { "ok": false, "error": { "code": "...", "message": "..." } }

// Errors that are safe to show to the user. Express 5 forwards errors
// from async handlers to errorHandler on its own.
//
// `extra` is merged into the error object, e.g. POST /offers uses it to
// return the offending ids as { ids: [...] }.
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

// Unmatched /api routes get the same envelope instead of Express's HTML 404.
export function notFound(req, res) {
  return fail(res, 404, 'NOT_FOUND', `Böyle bir uç nokta yok: ${req.method} ${req.path}`);
}

// Express recognizes error middleware by its 4 args, so `next` has to
// stay even though it's unused.
export function errorHandler(err, req, res, next) {
  if (err instanceof ApiError) {
    return fail(res, err.status, err.code, err.message, err.extra);
  }
  // Thrown by express.json() on a malformed body.
  if (err.type === 'entity.parse.failed') {
    return fail(res, 400, 'INVALID_JSON', 'İstek gövdesi geçerli bir JSON değil.');
  }
  console.error(err);
  return fail(res, 500, 'INTERNAL', 'Beklenmeyen bir hata oluştu.');
}
