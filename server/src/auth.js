import { Router } from 'express';

import { ApiError, ok } from './http.js';

const ROLES = ['employer', 'worker'];

// Two fixed accounts from the seed. No SMS or password: picking a role is
// the login. Tokens are fixed too ("dev-employer" / "dev-worker").
export function authRouter(store) {
  const router = Router();

  router.post('/auth/login', (req, res) => {
    // Express 5 leaves req.body undefined when the request isn't JSON.
    const role = req.body?.role;
    if (!ROLES.includes(role)) {
      throw new ApiError(400, 'INVALID_ROLE', 'role "employer" ya da "worker" olmalı.');
    }
    const user = store.read().users.find((u) => u.role === role);
    return ok(res, { token: user.token, role: user.role });
  });

  return router;
}

// Checks the Bearer token and role, then sets req.user.
//
// A wrong role returns 401 FORBIDDEN_ROLE because the spec asks for 401.
// 403 would be the correct status; the README mentions this.
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
