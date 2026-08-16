import 'dotenv/config';
import express from 'express';
import cors from 'cors';
import { logger } from './lib/logger';
import { initSocketService } from './services/socket.service';
import { initWorkers } from './services/queue.service';
import apiRouter from './routes/api.router';

const app = express();
import { initSentry } from './lib/sentry';

// Initialize Sentry (safe - only connects if SENTRY_DSN is set)
try {
  initSentry(app);
} catch (err: any) {
  logger.warn({ err: err.message }, 'Sentry initialization failed, continuing');
}

const PORT = process.env.PORT || 5000;

// ── CORS ────────────────────────────────────────────────────────────────────
const allowedOrigins = (process.env.ALLOWED_ORIGINS || 'http://localhost:3000,http://localhost:3001')
  .split(',')
  .map(o => o.trim());

app.use(cors({
  origin: (origin, callback) => {
    if (!origin || allowedOrigins.includes(origin) || allowedOrigins.includes('*')) {
      callback(null, true);
    } else {
      callback(new Error(`CORS blocked: ${origin}`));
    }
  },
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Idempotency-Key'],
}));

// ── Body Parsing ──────────────────────────────────────────────────────────────
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// ── Global Rate Limit ─────────────────────────────────────────────────────────
import { apiRateLimiter } from './middleware/rate-limiter';
app.use(apiRateLimiter);

// ── Request Logging ───────────────────────────────────────────────────────────
app.use((req, _res, next) => {
  logger.info({ method: req.method, url: req.url, ip: req.ip }, 'Incoming request');
  next();
});

// ── Metrics ───────────────────────────────────────────────────────────────────
import client from 'prom-client';
if (process.env.ENABLE_METRICS === 'true') {
  client.collectDefaultMetrics();
}
app.get('/metrics', async (_req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.send(await client.register.metrics());
});

import { validateEnvironment } from './config/env';
validateEnvironment();

// ── Root & Health Check ──────────────────────────────────────────────────────
app.get('/', (_req, res) => {
  res.json({
    status: 'ok',
    message: 'ORBIT Platform API is online',
    version: '1.0.0',
    environment: process.env.NODE_ENV || 'development',
    timestamp: new Date().toISOString()
  });
});

app.get('/health', (_req, res) => {
  const envCheck = validateEnvironment();
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    service: 'orbit-backend',
    envConfigured: envCheck.isValid,
    missingRequiredVars: envCheck.missing
  });
});

// ── API Routes ────────────────────────────────────────────────────────────────
import { setupSwagger } from './lib/swagger';
setupSwagger(app);
app.use('/api', apiRouter);

// ── Webhook Routes (raw body for signature verification) ──────────────────────
import webhookRouter from './routes/webhook.router';
app.use('/webhook', express.raw({ type: 'application/json' }), webhookRouter);

// ── 404 Handler ────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ── Error Handler ─────────────────────────────────────────────────────────────
if (process.env.SENTRY_DSN) {
  try {
    const Sentry = require('@sentry/node');
    if (Sentry.Handlers && Sentry.Handlers.errorHandler) {
      app.use(Sentry.Handlers.errorHandler());
    }
  } catch (err) {
    logger.warn('Failed to attach Sentry error handler');
  }
}

app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(err, 'Unhandled error');
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
  });
});

// ── Initialize Services ───────────────────────────────────────────────────────
try {
  initSocketService();
} catch (err: any) {
  logger.warn({ err: err.message }, 'Socket service initialization failed, continuing');
}

if (process.env.NODE_ENV !== 'test') {
  try {
    initWorkers();
  } catch (err: any) {
    logger.warn({ err: err.message }, 'Worker initialization failed, continuing');
  }
}

// ── Start HTTP Server (Local Development) ─────────────────────────────────────
if (process.env.NODE_ENV !== 'production' || process.env.FORCE_START_SERVER === 'true') {
  app.listen(PORT, () => {
    logger.info(`🚀 ORBIT Backend running on port ${PORT}`);
  });
}

// Export for Vercel Serverless
export default app;
