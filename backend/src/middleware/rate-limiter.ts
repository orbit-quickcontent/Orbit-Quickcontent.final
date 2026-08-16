import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { redis } from '../services/redis.service';

// Generic API Rate Limiter
export const apiRateLimiter = rateLimit({
  validate: false,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  store: new RedisStore({
    sendCommand: (...args: string[]) => redis.call(args[0], ...args.slice(1)) as any,
  }),
  message: {
    error: 'Too many requests from this IP, please try again after 15 minutes',
  },
});

// Stricter Rate Limiter for Authentication endpoints
export const authRateLimiter = rateLimit({
  validate: false,
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 10, // Limit each IP to 10 requests per `window`
  standardHeaders: true,
  legacyHeaders: false,
  store: new RedisStore({
    sendCommand: (...args: string[]) => redis.call(args[0], ...args.slice(1)) as any,
  }),
  message: {
    error: 'Too many authentication attempts from this IP, please try again after an hour',
  },
});
