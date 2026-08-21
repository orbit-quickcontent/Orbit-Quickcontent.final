import { Router, Request, Response } from 'express';
import prisma from '../lib/prisma';
import { dispatchQueue } from '../services/queue.service';
import { emitToClient, SOCKET_EVENTS } from '../services/socket.service';
import { logger } from '../lib/logger';

const router = Router();

// ── Direct Payment / Confirmation Webhook ─────────────────────────────────────
router.post('/payment-confirm', async (req: Request, res: Response) => {
  const { bookingId, paymentId } = req.body;

  if (!bookingId) {
    res.status(400).json({ error: 'Missing bookingId' });
    return;
  }

  try {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
    });

    if (!booking) {
      res.status(404).json({ error: 'Booking not found' });
      return;
    }

    await prisma.booking.update({
      where: { id: bookingId },
      data: {
        status: 'PAID',
        paymentStatus: 'SUCCESS',
        paymentId: paymentId || `pay_${Date.now()}`,
      },
    });

    emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: booking.id, status: 'PAID' });
    await dispatchQueue.add('dispatch', { bookingId: booking.id }, { jobId: `dispatch_${booking.id}` });
    logger.info({ bookingId: booking.id }, '✅ Booking confirmed & dispatch queued');

    res.json({ success: true, bookingId });
  } catch (err: any) {
    logger.error({ err: err.message }, 'Webhook confirmation error');
    res.status(500).json({ error: 'Internal processing error' });
  }
});

export default router;
