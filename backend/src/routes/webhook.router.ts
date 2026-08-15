import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import prisma from '../lib/prisma';
import { dispatchQueue } from '../services/queue.service';
import { handleCashfreeWebhook } from '../services/wallet.service';
import { emitToClient, SOCKET_EVENTS } from '../services/socket.service';
import { logger } from '../lib/logger';

const router = Router();

// ── Razorpay Payment Webhook ───────────────────────────────────────────────────
router.post('/razorpay', async (req: Request, res: Response) => {
  const signature = req.headers['x-razorpay-signature'] as string;
  const body = req.body; // raw Buffer from express.raw middleware

  if (!signature || !process.env.RAZORPAY_WEBHOOK_SECRET) {
    res.status(400).json({ error: 'Missing signature' }); return;
  }

  // Verify HMAC-SHA256 signature
  const expectedSig = crypto
    .createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET)
    .update(body)
    .digest('hex');

  if (!crypto.timingSafeEqual(Buffer.from(signature), Buffer.from(expectedSig))) {
    logger.warn('Razorpay webhook signature mismatch');
    res.status(400).json({ error: 'Invalid signature' }); return;
  }

  let event: any;
  try {
    event = JSON.parse(body.toString());
  } catch {
    res.status(400).json({ error: 'Invalid JSON' }); return;
  }

  logger.info({ event: event.event }, 'Razorpay webhook received');
  res.json({ status: 'ok' }); // Acknowledge immediately

  // Process asynchronously
  setImmediate(async () => {
    try {
      if (event.event === 'payment.captured') {
        const payment = event.payload.payment.entity;
        const orderId = payment.order_id;
        const paymentId = payment.id;

        // Idempotency: skip if already processed
        const existingPayment = await prisma.payment.findFirst({
          where: { razorpayOrderId: orderId, status: 'SUCCESS' },
        });
        if (existingPayment) { logger.warn({ orderId }, 'Duplicate payment webhook — ignored'); return; }

        // Find booking
        const booking = await prisma.booking.findFirst({
          where: { paymentOrderId: orderId },
        });
        if (!booking) { logger.error({ orderId }, 'No booking found for order'); return; }

        // Update payment and booking
        await prisma.$transaction([
          prisma.payment.updateMany({
            where: { razorpayOrderId: orderId },
            data: { status: 'SUCCESS', razorpayPaymentId: paymentId, processedAt: new Date(), webhookData: event.payload },
          }),
          prisma.booking.update({
            where: { id: booking.id },
            data: { status: 'PAID', paymentStatus: 'SUCCESS', paymentId },
          }),
        ]);

        emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: booking.id, status: 'PAID' });

        // Trigger dispatch
        await dispatchQueue.add('dispatch', { bookingId: booking.id }, { jobId: `dispatch_${booking.id}` });
        logger.info({ bookingId: booking.id }, '✅ Payment captured — dispatch queued');
      }
    } catch (err: any) {
      logger.error({ err: err.message }, 'Razorpay webhook processing error');
    }
  });
});

// ── Cashfree Payout Webhook ────────────────────────────────────────────────────
router.post('/cashfree', async (req: Request, res: Response) => {
  const signature = req.headers['x-cashfree-signature'] as string;
  const timestamp = req.headers['x-cashfree-timestamp'] as string;
  const body = req.body;

  // Verify Cashfree signature
  const expectedSig = crypto
    .createHmac('sha256', process.env.CASHFREE_CLIENT_SECRET!)
    .update(`${timestamp}${body.toString()}`)
    .digest('base64');

  if (signature !== expectedSig) {
    logger.warn('Cashfree webhook signature mismatch');
    res.status(400).json({ error: 'Invalid signature' }); return;
  }

  let event: any;
  try {
    event = JSON.parse(body.toString());
  } catch {
    res.status(400).json({ error: 'Invalid JSON' }); return;
  }

  res.json({ status: 'ok' });

  setImmediate(async () => {
    try {
      const transferId = event?.data?.transfer_id;
      const status = event?.data?.transfer_status;
      if (transferId) {
        const withdrawal = await prisma.withdrawal.findFirst({
          where: { cashfreeTransferId: transferId },
        });
        if (withdrawal) {
          await handleCashfreeWebhook(withdrawal.id, status, event.data);
        }
      }
    } catch (err: any) {
      logger.error({ err: err.message }, 'Cashfree webhook processing error');
    }
  });
});

export default router;
