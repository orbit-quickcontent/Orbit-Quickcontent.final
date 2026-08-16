import { logger } from '../lib/logger';

const requiredEnv = [
  'DATABASE_URL',
  'JWT_SECRET',
  'JWT_REFRESH_SECRET',
];

const optionalEnv = [
  'SUPABASE_URL',
  'SUPABASE_SERVICE_ROLE_KEY',
  'REDIS_URL',
  'QSTASH_TOKEN',
  'RAZORPAY_KEY_ID',
  'RAZORPAY_KEY_SECRET',
  'CASHFREE_APP_ID',
  'CASHFREE_SECRET_KEY',
];

export function validateEnvironment(): { isValid: boolean; missing: string[] } {
  const missing = requiredEnv.filter((key) => !process.env[key]);

  if (missing.length > 0) {
    logger.warn({ missing }, '⚠️ Missing required environment variables');
  }

  const missingOptional = optionalEnv.filter((key) => !process.env[key]);
  if (missingOptional.length > 0) {
    logger.info({ missingOptional }, 'ℹ️ Optional environment variables not set');
  }

  return {
    isValid: missing.length === 0,
    missing,
  };
}
