import { logger } from '../lib/logger';

const requiredEnv = [
  'JWT_SECRET',
  'JWT_REFRESH_SECRET',
];

const optionalEnv = [
  'DATABASE_URL',
  'FIREBASE_PROJECT_ID',
  'FIREBASE_CLIENT_EMAIL',
  'FIREBASE_PRIVATE_KEY',
  'FIREBASE_STORAGE_BUCKET',
  'REDIS_URL',
  'VALKEY_URL',
  'QSTASH_TOKEN',
  'ZAVU_API_KEY',
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
