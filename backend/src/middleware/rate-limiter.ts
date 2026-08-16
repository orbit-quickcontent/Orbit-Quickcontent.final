import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { getRedisClient, isRedisAvailable } from '../services/redis.service';
import { logger } from '../lib/logger';

// Fallback in-memory store for serverless environments (no persistent Redis)
class MemoryStore {
  private store: Map<string, { count: number; resetTime: number }> = new Map();

  async incr(key: string) {
    const now = Date.now();
    const entry = this.store.get(key);

    if (!entry || entry.resetTime < now) {
      // Create new entry or reset expired one
      this.store.set(key, { count: 1, resetTime: now + 15 * 60 * 1000 }); // 15 min window
      return 1;
    }

    entry.count++;
    return entry.count;
  }

  async resetKey(key: string) {
    this.store.delete(key);
  }

  async reset() {
    this.store.clear();
  }
}

const memoryStore = new MemoryStore();

// Dynamically choose store based on Redis availability
const createRateLimitStore = () => {
  const redis = getRedisClient();

  if (redis && isRedisAvailable()) {
    logger.info('Using Redis store for rate limiting');
    return new RedisStore({
      sendCommand: (...args: string[]) => redis.call(args[0], ...args.slice(1)) as any,
    });
  }

  // Fallback to memory store (for serverless environments without Redis)
  logger.info('Using in-memory store for rate limiting (serverless mode)');
  return memoryStore as any;
};

// Generic API Rate Limiter
export const apiRateLimiter = rateLimit({
  validate: false,
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // Limit each IP to 100 requests per `window` (here, per 15 minutes)
  standardHeaders: true, // Return rate limit info in the `RateLimit-*` headers
  legacyHeaders: false, // Disable the `X-RateLimit-*` headers
  store: createRateLimitStore(),
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
  store: createRateLimitStore(),
  message: {
    error: 'Too many authentication attempts from this IP, please try again after an hour',
  },
});
