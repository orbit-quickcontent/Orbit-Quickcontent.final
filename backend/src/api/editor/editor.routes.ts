import { Router } from 'express';
import { z } from 'zod';
import prisma from '../../lib/prisma';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { emitToEditor, emitToBooking, emitToClient, SOCKET_EVENTS } from '../../services/socket.service';
import { creditPartnerEarning } from '../../services/wallet.service';
import { logger } from '../../lib/logger';

const router = Router();

// GET /api/editor/jobs — Available jobs pool
router.get('/jobs', authenticate, authorize('EDITOR'), async (req, res) => {
  const jobs = await prisma.booking.findMany({
    where: { status: 'EDITOR_AVAILABLE' },
    include: { package: true, mediaAssets: { where: { type: 'RAW_FOOTAGE', isVerified: true } } },
    orderBy: { uploadCompletedAt: 'asc' },
    take: 20,
  });
  res.json(jobs);
});

// GET /api/editor/jobs/:id
router.get('/jobs/:id', authenticate, authorize('EDITOR'), async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id },
    include: {
      package: true,
      mediaAssets: true,
      user: { select: { id: true, name: true, email: true, phone: true, avatar: true } },
    },
  });
  if (!booking) { res.status(404).json({ error: 'Job not found' }); return; }
  res.json(booking);
});

// POST /api/editor/jobs/:id/claim — Atomic editor claim
router.post('/jobs/:id/claim', authenticate, authorize('EDITOR'), async (req, res) => {
  const editorId = req.user!.editorId!;
  const bookingId = req.params.id;

  try {
    const result = await prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        select: { status: true, editorId: true, userId: true },
      });
      if (!booking || booking.status !== 'EDITOR_AVAILABLE') {
        throw new Error('Job no longer available');
      }
      if (booking.editorId) throw new Error('Job already claimed');

      // Check editor not already on a job
      const busyEditor = await tx.booking.findFirst({
        where: { editorId, status: { in: ['EDITOR_ASSIGNED', 'EDITING', 'QUALITY_CHECK'] } },
      });
      if (busyEditor) throw new Error('You already have an active job');

      await tx.booking.update({
        where: { id: bookingId },
        data: { editorId, status: 'EDITOR_ASSIGNED', editorAssignedAt: new Date() },
      });

      await tx.editorAssignment.create({
        data: { bookingId, editorId, deadline: new Date(Date.now() + 60 * 60 * 1000) }, // 1hr
      });

      return booking;
    });

    emitToBooking(bookingId, SOCKET_EVENTS.EDITOR_JOB_CLAIMED, { bookingId, editorId });
    logger.info({ bookingId, editorId }, 'Editor claimed job atomically');
    res.json({ success: true });
  } catch (err: any) {
    res.status(409).json({ error: err.message });
  }
});

// POST /api/editor/jobs/:id/start — Start editing
router.post('/jobs/:id/start', authenticate, authorize('EDITOR'), async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id, editorId: req.user!.editorId },
  });
  if (!booking || booking.status !== 'EDITOR_ASSIGNED') {
    res.status(400).json({ error: 'Invalid state' }); return;
  }

  await prisma.booking.update({
    where: { id: req.params.id },
    data: { status: 'EDITING', editingStartedAt: new Date() },
  });
  emitToBooking(req.params.id, SOCKET_EVENTS.EDITING_STARTED, { bookingId: req.params.id });
  res.json({ success: true });
});

// POST /api/editor/jobs/:id/deliver — Submit final reel → QC
router.post('/jobs/:id/deliver', authenticate, authorize('EDITOR'), async (req, res) => {
  const schema = z.object({ reelUrl: z.string().url(), reelKey: z.string() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Reel URL required' }); return; }

  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id, editorId: req.user!.editorId },
  });
  if (!booking || booking.status !== 'EDITING') {
    res.status(400).json({ error: 'Booking not in editing state' }); return;
  }

  await prisma.$transaction([
    prisma.booking.update({
      where: { id: req.params.id },
      data: { status: 'QUALITY_CHECK', masterReelUrl: parsed.data.reelUrl },
    }),
    prisma.mediaAsset.create({
      data: {
        bookingId: req.params.id,
        type: 'FINAL_REEL',
        url: parsed.data.reelUrl,
        key: parsed.data.reelKey,
        isVerified: false,
        uploadedBy: req.user!.editorId,
      },
    }),
  ]);

  // Auto-approve QC for now (admin can review in dashboard)
  await prisma.booking.update({
    where: { id: req.params.id },
    data: { status: 'DELIVERED', deliveredAt: new Date() },
  });

  emitToBooking(req.params.id, SOCKET_EVENTS.BOOKING_DELIVERED, {
    bookingId: req.params.id,
    reelUrl: parsed.data.reelUrl,
  });
  emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_DELIVERED, {
    bookingId: req.params.id,
    message: 'Your ORBIT reel is ready!',
    reelUrl: parsed.data.reelUrl,
  });

  // Credit ₹500 to partner
  if (booking.partnerId) {
    await creditPartnerEarning(req.params.id, booking.partnerId);
  }

  logger.info({ bookingId: req.params.id }, '🎬 Booking delivered and partner credited');
  res.json({ success: true });
});

export default router;
