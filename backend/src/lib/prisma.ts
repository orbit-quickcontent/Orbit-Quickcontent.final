import { PrismaClient } from '@prisma/client';
import { logger } from '../lib/logger';

declare global {
  // eslint-disable-next-line no-var
  var __prisma: PrismaClient | undefined;
}

// Singleton pattern to prevent multiple instances in dev (hot reload)
export const prisma = globalThis.__prisma ?? new PrismaClient({
  log: process.env.NODE_ENV === 'development'
    ? [{ emit: 'event', level: 'query' }, { emit: 'event', level: 'error' }]
    : [{ emit: 'event', level: 'error' }],
});

if (process.env.NODE_ENV === 'development') {
  prisma.$on('query' as never, (e: any) => {
    logger.debug({ query: e.query, duration: `${e.duration}ms` }, 'Prisma query');
  });
}

prisma.$on('error' as never, (e: any) => {
  logger.error(e, 'Prisma error');
});

if (process.env.NODE_ENV !== 'production') {
  globalThis.__prisma = prisma;
}

export default prisma;
