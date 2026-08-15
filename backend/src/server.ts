import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { createServer } from 'http';
import rateLimit from 'express-rate-limit';
import { logger } from './lib/logger';
import { initSocketService } from './services/socket.service';
import { initWorkers } from './services/queue.service';
import apiRouter from './routes/api.router';

dotenv.config();

const app = express();
const httpServer = createServer(app);
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
app.use(rateLimit({
  windowMs: 60 * 1000,
  max: 200,
  standardHeaders: true,
  legacyHeaders: false,
  message: { error: 'Too many requests, please try again later.' },
}));

// ── Request Logging ───────────────────────────────────────────────────────────
app.use((req, _res, next) => {
  logger.info({ method: req.method, url: req.url, ip: req.ip }, 'Incoming request');
  next();
});

// ── Health Check ──────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString(), service: 'orbit-backend' });
});

// ── API Routes ────────────────────────────────────────────────────────────────
app.use('/api', apiRouter);

// ── Webhook Routes (raw body for signature verification) ──────────────────────
import webhookRouter from './routes/webhook.router';
app.use('/webhook', express.raw({ type: 'application/json' }), webhookRouter);

// ── 404 Handler ────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// ── Error Handler ─────────────────────────────────────────────────────────────
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  logger.error(err, 'Unhandled error');
  res.status(err.status || 500).json({
    error: process.env.NODE_ENV === 'production' ? 'Internal server error' : err.message,
  });
});

// ── Start Socket.IO ───────────────────────────────────────────────────────────
initSocketService(httpServer);

// ── Start BullMQ Workers ──────────────────────────────────────────────────────
if (process.env.NODE_ENV !== 'test') {
  initWorkers();
}

// ── Start HTTP Server ─────────────────────────────────────────────────────────
httpServer.listen(PORT, () => {
  logger.info(`🚀 ORBIT Backend running on port ${PORT}`);
});

export { app, httpServer };
