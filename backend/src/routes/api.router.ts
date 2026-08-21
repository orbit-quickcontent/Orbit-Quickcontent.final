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
  try {
    let packages = await prisma.package.findMany({
      where: { isActive: true },
      orderBy: { priceDisplay: 'asc' },
    });

    if (!packages || packages.length === 0) {
      // Auto-seed packages if none exist
      packages = await Promise.all([
        prisma.package.upsert({
          where: { tier: 'QUICK' },
          update: {},
          create: {
            name: 'Quick Reel',
            tier: 'QUICK',
            price: 99900,
            priceDisplay: 999,
            partnerPayout: 400,
            focus: '1 High-Impact 9:16 Reel',
            deliveryTime: '60 min delivery',
            features: ['1 Short-form Reel (30-60s)', 'Basic Color Grading', 'Trending Audio Sync', '1080p MP4 Export'],
            popular: false,
            isActive: true,
          },
        }),
        prisma.package.upsert({
          where: { tier: 'PERSONALIZED' },
          update: {},
          create: {
            name: 'Creator Standard',
            tier: 'PERSONALIZED',
            price: 199900,
            priceDisplay: 1999,
            partnerPayout: 500,
            focus: '3 Polished Reels + B-Roll',
            deliveryTime: '120 min delivery',
            features: ['3 Short-form Reels', 'Advanced Color Grading', 'Motion Captions', '4K Master Export'],
            popular: true,
            isActive: true,
          },
        }),
        prisma.package.upsert({
          where: { tier: 'PROFESSIONAL' },
          update: {},
          create: {
            name: 'Brand Premium',
            tier: 'PROFESSIONAL',
            price: 499900,
            priceDisplay: 4999,
            partnerPayout: 1000,
            focus: '6 Cinematic Reels + Brand Kit',
            deliveryTime: 'Same Day delivery',
            features: ['6 Master Reels', 'Motion Graphics & Text', 'Sound Design & VO', 'Custom Brand Kit'],
            popular: false,
            isActive: true,
          },
        }),
      ]);
    }

    res.json(packages);
  } catch (err) {
    // Fallback static JSON if database connection has temporary issue
    res.json([
      {
        id: 'pkg_quick',
        name: 'Quick Reel',
        tier: 'QUICK',
        price: 99900,
        priceDisplay: 999,
        focus: '1 High-Impact 9:16 Reel',
        deliveryTime: '60 min delivery',
        features: ['1 Short-form Reel', 'Basic Color Grading', 'Trending Audio Sync'],
        popular: false,
        isActive: true,
      },
      {
        id: 'pkg_standard',
        name: 'Creator Standard',
        tier: 'PERSONALIZED',
        price: 199900,
        priceDisplay: 1999,
        focus: '3 Polished Reels + B-Roll',
        deliveryTime: '120 min delivery',
        features: ['3 Short-form Reels', 'Advanced Color Grading', 'Motion Captions'],
        popular: true,
        isActive: true,
      },
      {
        id: 'pkg_premium',
        name: 'Brand Premium',
        tier: 'PROFESSIONAL',
        price: 499900,
        priceDisplay: 4999,
        focus: '6 Cinematic Reels + Brand Kit',
        deliveryTime: 'Same Day delivery',
        features: ['6 Master Reels', 'Motion Graphics', 'Sound Design'],
        popular: false,
        isActive: true,
      },
    ]);
  }
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
