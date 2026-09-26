import { Router } from 'express';

import { ApiError, ok } from './http.js';

const ROLES = ['employer', 'worker'];

// Case için sabit iki hesap (seed users): SMS / şifre yok, rol seçmek
// giriş yapmak demek. Token da seed'de sabit ("dev-employer" / "dev-worker").
export function authRouter(store) {
  const router = Router();

  router.post('/auth/login', (req, res) => {
    // Content-Type JSON değilse Express 5'te req.body undefined geliyor.
    const role = req.body?.role;
    if (!ROLES.includes(role)) {
      throw new ApiError(400, 'INVALID_ROLE', 'role "employer" ya da "worker" olmalı.');
    }
    const user = store.read().users.find((u) => u.role === role);
    return ok(res, { token: user.token, role: user.role });
  });

  return router;
}

// Bearer token'ı doğrular ve rolü kontrol eder; geçerse req.user'ı doldurur.
//
// Yanlış rol de 401 + FORBIDDEN_ROLE: spec böyle istiyor ("yanlış rol
// 401"). HTTP semantiğinde doğrusu 403 — README'de not olarak geçiyor.
export function requireRole(store, role) {
  return (req, res, next) => {
    const [scheme, token] = (req.get('Authorization') ?? '').split(' ');
    const user =
      scheme === 'Bearer' && store.read().users.find((u) => u.token === token);
    if (!user) {
      throw new ApiError(401, 'UNAUTHORIZED', 'Geçerli bir Bearer token gerekli.');
    }
    if (user.role !== role) {
      throw new ApiError(401, 'FORBIDDEN_ROLE', `Bu işlem yalnızca "${role}" rolüne açık.`);
    }
    req.user = user;
    next();
  };
}
