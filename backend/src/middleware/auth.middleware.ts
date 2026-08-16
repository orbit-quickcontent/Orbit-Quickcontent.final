import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { UserRole } from '@prisma/client';
import rateLimit from 'express-rate-limit';
import { logger } from '../lib/logger';

export interface AuthUser {
  id: string;
  email: string;
  role: UserRole;
  partnerId?: string;
  editorId?: string;
}

declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}

// ── JWT Verify Middleware ─────────────────────────────────────────────────────
export function authenticate(req: Request, res: Response, next: NextFunction): void {
  const token = req.headers.authorization?.replace('Bearer ', '');
  if (!token) {
    res.status(401).json({ error: 'Authentication required' });
    return;
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET!) as AuthUser;
    req.user = payload;
    next();
  } catch (err: any) {
    if (err.name === 'TokenExpiredError') {
      res.status(401).json({ error: 'Token expired', code: 'TOKEN_EXPIRED' });
    } else {
      res.status(401).json({ error: 'Invalid token' });
    }
  }
}

// ── Role-Based Access Control ─────────────────────────────────────────────────
export function authorize(...roles: UserRole[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    if (!req.user) { res.status(401).json({ error: 'Authentication required' }); return; }
    if (!roles.includes(req.user.role)) {
      logger.warn({ userId: req.user.id, role: req.user.role, required: roles }, 'RBAC denied');
      res.status(403).json({ error: 'Insufficient permissions' });
      return;
    }
    next();
  };
}

// ── Issue JWT Tokens ──────────────────────────────────────────────────────────
export function issueTokens(user: AuthUser): { accessToken: string; refreshToken: string } {
  const accessToken = jwt.sign(user, process.env.JWT_SECRET!, { expiresIn: '15m' });
  const refreshToken = jwt.sign({ id: user.id }, process.env.JWT_REFRESH_SECRET!, { expiresIn: '7d' });
  return { accessToken, refreshToken };
}

export function verifyRefreshToken(token: string): { id: string } | null {
  try {
    return jwt.verify(token, process.env.JWT_REFRESH_SECRET!) as { id: string };
  } catch {
    return null;
  }
}

// ── Rate Limiters ─────────────────────────────────────────────────────────────
export const rateLimits = {
  sendOtp: rateLimit({ validate: false, windowMs: 60_000, max: 5, message: { error: 'Too many OTP requests' }, keyGenerator: (req) => req.ip || 'unknown' }),
  verifyOtp: rateLimit({ validate: false, windowMs: 60_000, max: 10, message: { error: 'Too many OTP attempts' }, keyGenerator: (req) => req.ip || 'unknown' }),
  bookings: rateLimit({ validate: false, windowMs: 60_000, max: 5, message: { error: 'Too many booking requests' }, keyGenerator: (req) => req.user?.id || req.ip || 'unknown' }),
  withdraw: rateLimit({ validate: false, windowMs: 3_600_000, max: 2, message: { error: 'Too many withdrawal requests' }, keyGenerator: (req) => req.user?.id || 'unknown' }),
  admin: rateLimit({ validate: false, windowMs: 60_000, max: 100, message: { error: 'Rate limit exceeded' }, keyGenerator: (req) => req.user?.id || req.ip || 'unknown' }),
  verifyCode: rateLimit({ validate: false, windowMs: 60_000, max: 5, message: { error: 'Too many code verification attempts' }, keyGenerator: (req) => req.user?.id || req.ip || 'unknown' }),
  locationUpdate: rateLimit({ validate: false, windowMs: 60_000, max: 30, message: { error: 'Location update rate limit exceeded' }, keyGenerator: (req) => req.user?.id || 'unknown' }),
};
