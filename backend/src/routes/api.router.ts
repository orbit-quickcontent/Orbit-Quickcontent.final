import { Router } from 'express';
import authRouter from '../api/auth/auth.routes';
import partnerRouter from '../api/partners/partner.routes';
import bookingRouter from '../api/bookings/booking.routes';
import walletRouter from '../api/wallet/wallet.routes';
import mapsRouter from '../api/maps/maps.routes';
import mediaRouter from '../api/media/media.routes';
import editorRouter from '../api/editor/editor.routes';
import adminRouter from '../api/admin/admin.routes';
import { authenticate } from '../middleware/auth.middleware';
import prisma from '../lib/prisma';

const router = Router();

import { authRateLimiter } from '../middleware/rate-limiter';

// ── Auth ──────────────────────────────────────────────────────────────────────
router.use('/auth', authRateLimiter, authRouter);

// ── Partner ───────────────────────────────────────────────────────────────────
router.use('/partner', partnerRouter);

// ── Bookings ──────────────────────────────────────────────────────────────────
router.use('/bookings', bookingRouter);

// ── Wallet ────────────────────────────────────────────────────────────────────
router.use('/wallet', walletRouter);

// ── Maps & Location ───────────────────────────────────────────────────────────
router.use('/maps', mapsRouter);
router.use('/location', mapsRouter); // Alias for /api/location/update

// ── Media (R2 Upload) ─────────────────────────────────────────────────────────
router.use('/media', mediaRouter);

// ── Editor ────────────────────────────────────────────────────────────────────
router.use('/editor', editorRouter);

// ── Admin ─────────────────────────────────────────────────────────────────────
router.use('/admin', adminRouter);

// ── Internal Serverless Jobs (QStash) ─────────────────────────────────────────
import jobsRouter from './jobs.router';
router.use('/internal/jobs', jobsRouter);

// ── Packages ──────────────────────────────────────────────────────────────────
router.get('/packages', async (_req, res) => {
  const packages = await prisma.package.findMany({
    where: { isActive: true },
    orderBy: { priceDisplay: 'asc' },
  });
  res.json(packages);
});

// ── Notifications ─────────────────────────────────────────────────────────────
router.get('/notifications', authenticate, async (req, res) => {
  const notifications = await prisma.notification.findMany({
    where: { userId: req.user!.id },
    orderBy: { createdAt: 'desc' },
    take: 50,
  });
  res.json(notifications);
});

router.patch('/notifications/:id/read', authenticate, async (req, res) => {
  await prisma.notification.updateMany({
    where: { id: req.params.id, userId: req.user!.id },
    data: { isRead: true, readAt: new Date() },
  });
  res.json({ success: true });
});

router.patch('/notifications/read-all', authenticate, async (req, res) => {
  await prisma.notification.updateMany({
    where: { userId: req.user!.id, isRead: false },
    data: { isRead: true, readAt: new Date() },
  });
  res.json({ success: true });
});

export default router;
