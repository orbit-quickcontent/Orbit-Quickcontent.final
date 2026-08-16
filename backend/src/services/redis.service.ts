import Redis from 'ioredis';
import { logger } from '../lib/logger';

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

// Main Redis client
export const redis = new Redis(redisUrl, {
  maxRetriesPerRequest: 3,
  retryStrategy: (times: number) => Math.min(times * 100, 3000),
  reconnectOnError: (err) => {
    logger.warn({ err: err.message }, 'Redis reconnect on error');
    return true;
  },
  lazyConnect: false,
});

redis.on('connect', () => logger.info('✅ Redis connected'));
redis.on('error', (err) => logger.error({ err: err.message }, '❌ Redis error'));
redis.on('reconnecting', () => logger.warn('♻️  Redis reconnecting...'));



// ── Key patterns ──────────────────────────────────────────────────────────────
export const REDIS_KEYS = {
  // Partner geo location set
  PARTNERS_GEO: 'orbit:partners:geo',

  // Individual partner location data
  partnerLocation: (partnerId: string) => `orbit:partner:${partnerId}:location`,

  // Partner online status
  partnerStatus: (partnerId: string) => `orbit:partner:${partnerId}:status`,

  // Booking dispatch lock (atomic acceptance)
  bookingDispatchLock: (bookingId: string) => `orbit:booking:${bookingId}:dispatch:lock`,

  // Active dispatch state
  bookingDispatch: (bookingId: string) => `orbit:booking:${bookingId}:dispatch`,

  // Partner busy state
  partnerBusy: (partnerId: string) => `orbit:partner:${partnerId}:busy`,

  // Wallet cache
  walletCache: (partnerId: string) => `orbit:wallet:${partnerId}`,

  // OTP rate limit
  otpRateLimit: (email: string) => `orbit:otp:ratelimit:${email}`,
  otpResendCooldown: (email: string) => `orbit:otp:cooldown:${email}`,
} as const;

export const LOCATION_TTL = parseInt(process.env.PARTNER_LOCATION_TTL_SECONDS || '60', 10);

// ── Partner Location ──────────────────────────────────────────────────────────

export async function updatePartnerLocation(
  partnerId: string,
  lat: number,
  lng: number,
  metadata?: Record<string, string>
) {
  const pipeline = redis.pipeline();

  // Update GEO index
  pipeline.geoadd(REDIS_KEYS.PARTNERS_GEO, lng, lat, partnerId);

  // Store full location metadata with TTL
  const locationData = {
    lat: lat.toString(),
    lng: lng.toString(),
    updatedAt: Date.now().toString(),
    ...metadata,
  };
  pipeline.hset(REDIS_KEYS.partnerLocation(partnerId), locationData);
  pipeline.expire(REDIS_KEYS.partnerLocation(partnerId), LOCATION_TTL);

  await pipeline.exec();
}

export async function removePartnerFromGeo(partnerId: string) {
  await redis.pipeline()
    .zrem(REDIS_KEYS.PARTNERS_GEO, partnerId)
    .del(REDIS_KEYS.partnerLocation(partnerId))
    .del(REDIS_KEYS.partnerStatus(partnerId))
    .exec();
}

export async function findNearbyPartners(
  lat: number,
  lng: number,
  radiusKm: number
): Promise<{ id: string; distanceKm: number }[]> {
  // GEORADIUS returns [member, distance] pairs
  const results = await redis.georadius(
    REDIS_KEYS.PARTNERS_GEO,
    lng,
    lat,
    radiusKm,
    'km',
    'WITHCOORD',
    'WITHDIST',
    'ASC',
    'COUNT',
    50
  ) as any[];

  return results.map((r: any) => ({
    id: r[0] as string,
    distanceKm: parseFloat(r[1] as string),
  }));
}

export async function getPartnerLocation(partnerId: string) {
  return redis.hgetall(REDIS_KEYS.partnerLocation(partnerId));
}

export async function setPartnerOnline(partnerId: string, lat: number, lng: number) {
  await Promise.all([
    updatePartnerLocation(partnerId, lat, lng),
    redis.setex(REDIS_KEYS.partnerStatus(partnerId), LOCATION_TTL * 5, 'online'),
  ]);
}

export async function setPartnerOffline(partnerId: string) {
  await removePartnerFromGeo(partnerId);
}

export async function setPartnerBusy(partnerId: string, bookingId: string) {
  await redis.setex(REDIS_KEYS.partnerBusy(partnerId), 7200, bookingId); // 2hr max
}

export async function setPartnerAvailable(partnerId: string) {
  await redis.del(REDIS_KEYS.partnerBusy(partnerId));
}

export async function isPartnerBusy(partnerId: string): Promise<boolean> {
  const v = await redis.get(REDIS_KEYS.partnerBusy(partnerId));
  return v !== null;
}

export default redis;
