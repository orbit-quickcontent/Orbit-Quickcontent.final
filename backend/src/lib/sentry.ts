import * as Sentry from '@sentry/node';
import { nodeProfilingIntegration } from '@sentry/profiling-node';

export function initSentry(app: import('express').Express) {
  if (process.env.SENTRY_DSN) {
    Sentry.init({
      dsn: process.env.SENTRY_DSN,
      integrations: [],
      tracesSampleRate: 0.01, // 1% of transactions
      profilesSampleRate: 0.01,
      autoSessionTracking: false, // GlitchTip does not support sessions
      environment: process.env.NODE_ENV || 'development',
    });
  }
}
