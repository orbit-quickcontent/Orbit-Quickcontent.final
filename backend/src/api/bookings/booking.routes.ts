import { Router } from 'express';
import { z } from 'zod';
import Razorpay from 'razorpay';
import prisma from '../../lib/prisma';
import { authenticate, authorize, rateLimits } from '../../middleware/auth.middleware';
import { acceptBooking, recordStatusChange } from '../../services/dispatch.service';
import { emitToBooking, emitToClient, emitToPartner, SOCKET_EVENTS } from '../../services/socket.service';
import { setPartnerAvailable } from '../../services/redis.service';
import { sendBookingNotification } from '../../services/fcm.service';
import { reverseGeocode } from '../../services/maps.service';

const router = Router();

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID!,
  key_secret: process.env.RAZORPAY_KEY_SECRET!,
});

// ── GET /api/bookings — List user's bookings ───────────────────────────────────
router.get('/', authenticate, async (req, res) => {
  const { status, page = '1', limit = '20' } = req.query;
  const skip = (parseInt(page as string) - 1) * parseInt(limit as string);

  const where: any = {};
  if (req.user!.role === 'CLIENT') where.userId = req.user!.id;
  else if (req.user!.role === 'PARTNER') where.partnerId = req.user!.partnerId;
  if (status) where.status = status;

  const [bookings, total] = await Promise.all([
    prisma.booking.findMany({
      where,
      include: { package: true, partner: { include: { user: { select: { name: true, avatar: true } } } } },
      orderBy: { createdAt: 'desc' },
      skip,
      take: parseInt(limit as string),
    }),
    prisma.booking.count({ where }),
  ]);

  res.json({ bookings, total, page: parseInt(page as string), pages: Math.ceil(total / parseInt(limit as string)) });
});

// ── GET /api/bookings/:id ─────────────────────────────────────────────────────
router.get('/:id', authenticate, async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id },
    include: {
      package: true,
      partner: { include: { user: { select: { name: true, avatar: true, email: true } } } },
      statusHistory: { orderBy: { createdAt: 'asc' } },
      mediaAssets: true,
    },
  });
  if (!booking) { res.status(404).json({ error: 'Booking not found' }); return; }
  res.json(booking);
});

// ── POST /api/bookings — Create booking + Razorpay order ─────────────────────
router.post('/', authenticate, authorize('CLIENT'), rateLimits.bookings, async (req, res) => {
  const schema = z.object({
    packageId: z.string(),
    latitude: z.number(),
    longitude: z.number(),
    address: z.string().optional(),
    bookingDate: z.string().datetime(),
    timeSlot: z.string(),
    notes: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.issues[0].message }); return; }

  // Get package (authoritative price from DB — never trust client price)
  const pkg = await prisma.package.findUnique({ where: { id: parsed.data.packageId, isActive: true } });
  if (!pkg) { res.status(404).json({ error: 'Package not found' }); return; }

  // Reverse geocode if no address
  const address = parsed.data.address ||
    await reverseGeocode(parsed.data.latitude, parsed.data.longitude);

  // Create Razorpay order
  const rzpOrder = await razorpay.orders.create({
    amount: pkg.price, // Already in paise
    currency: 'INR',
    receipt: `orbit_${Date.now()}`,
  });

  const idempotencyKey = `payment_${rzpOrder.id}`;

  // Create booking in DB
  const booking = await prisma.booking.create({
    data: {
      userId: req.user!.id,
      packageId: pkg.id,
      status: 'PENDING_PAYMENT',
      paymentStatus: 'UNPAID',
      paymentOrderId: rzpOrder.id,
      latitude: parsed.data.latitude,
      longitude: parsed.data.longitude,
      address,
      bookingDate: new Date(parsed.data.bookingDate),
      timeSlot: parsed.data.timeSlot,
      notes: parsed.data.notes,
    },
  });

  await prisma.payment.create({
    data: {
      bookingId: booking.id,
      razorpayOrderId: rzpOrder.id,
      amount: pkg.price,
      status: 'UNPAID',
      idempotencyKey,
    },
  });

  await recordStatusChange(booking.id, null, 'PENDING_PAYMENT', req.user!.id);

  res.status(201).json({
    booking,
    payment: {
      orderId: rzpOrder.id,
      amount: pkg.price,
      currency: 'INR',
      keyId: process.env.RAZORPAY_KEY_ID,
    },
  });
});

// ── POST /api/bookings/:id/accept — Partner accepts ──────────────────────────
router.post('/:id/accept', authenticate, authorize('PARTNER'), async (req, res) => {
  const result = await acceptBooking(req.params.id, req.user!.partnerId!);
  if (!result.success) { res.status(409).json(result); return; }
  res.json(result);
});

// ── POST /api/bookings/:id/en-route — Partner is heading to client ────────────
router.post('/:id/en-route', authenticate, authorize('PARTNER'), async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id, partnerId: req.user!.partnerId },
  });
  if (!booking || booking.status !== 'PARTNER_ASSIGNED') {
    res.status(400).json({ error: 'Invalid state for en-route transition. Booking must be in PARTNER_ASSIGNED status.' });
    return;
  }

  await prisma.booking.update({
    where: { id: req.params.id },
    data: { status: 'EN_ROUTE' },
  });
  await recordStatusChange(req.params.id, 'PARTNER_ASSIGNED', 'EN_ROUTE', req.user!.partnerId!);
  emitToBooking(req.params.id, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: req.params.id, status: 'EN_ROUTE' });
  emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: req.params.id, status: 'EN_ROUTE' });

  // Send push notification to client
  const clientUser = await prisma.user.findUnique({ where: { id: booking.userId }, select: { fcmToken: true } });
  if (clientUser?.fcmToken) {
    await sendBookingNotification(clientUser.fcmToken, {
      title: '🚗 Partner En Route',
      body: 'Your partner is heading to your location!',
      data: { type: 'BOOKING_UPDATE', bookingId: req.params.id, status: 'EN_ROUTE' },
    });
  }

  res.json({ success: true });
});

// ── POST /api/bookings/:id/decline ────────────────────────────────────────────
router.post('/:id/decline', authenticate, authorize('PARTNER'), async (req, res) => {
  const bookingId = req.params.id;
  const partnerId = req.user!.partnerId!;

  await prisma.workDispatch.updateMany({
    where: { bookingId, partnerId, status: 'PENDING' },
    data: { status: 'DECLINED', respondedAt: new Date() },
  });

  const booking = await prisma.booking.findUnique({ where: { id: bookingId } });
  if (booking) {
    const declinedBy = [...((booking.declinedBy as string[]) || []), partnerId];
    await prisma.booking.update({ where: { id: bookingId }, data: { declinedBy } });
  }

  res.json({ success: true });
});

// ── POST /api/bookings/:id/arrived ────────────────────────────────────────────
router.post('/:id/arrived', authenticate, authorize('PARTNER'), async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id, partnerId: req.user!.partnerId },
  });
  if (!booking || booking.status !== 'EN_ROUTE') {
    res.status(400).json({ error: 'Invalid booking state for arrival confirmation' }); return;
  }

  await prisma.booking.update({
    where: { id: req.params.id },
    data: { status: 'ARRIVED', arrivedAt: new Date() },
  });
  await recordStatusChange(req.params.id, 'EN_ROUTE', 'ARRIVED', req.user!.partnerId!);
  emitToBooking(req.params.id, SOCKET_EVENTS.PARTNER_ARRIVED, { bookingId: req.params.id });
  emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: req.params.id, status: 'ARRIVED' });

  res.json({ success: true });
});

// ── POST /api/bookings/:id/start-shoot ───────────────────────────────────────
router.post('/:id/start-shoot', authenticate, authorize('PARTNER'), async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id, partnerId: req.user!.partnerId },
  });
  if (!booking || booking.status !== 'ARRIVED') {
    res.status(400).json({ error: 'Partner must arrive before starting shoot' }); return;
  }

  await prisma.booking.update({
    where: { id: req.params.id },
    data: { status: 'SHOOTING', shootingStartedAt: new Date() },
  });
  await recordStatusChange(req.params.id, 'ARRIVED', 'SHOOTING', req.user!.partnerId!);
  emitToBooking(req.params.id, SOCKET_EVENTS.SHOOTING_STARTED, { bookingId: req.params.id });
  emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: req.params.id, status: 'SHOOTING' });

  res.json({ success: true });
});

// ── POST /api/bookings/:id/complete-shoot ────────────────────────────────────
router.post('/:id/complete-shoot', authenticate, authorize('PARTNER'), async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id, partnerId: req.user!.partnerId },
  });
  if (!booking || booking.status !== 'SHOOTING') {
    res.status(400).json({ error: 'Shooting must be in progress' }); return;
  }

  await prisma.booking.update({
    where: { id: req.params.id },
    data: { status: 'UPLOADING', shootingEndedAt: new Date() },
  });
  await recordStatusChange(req.params.id, 'SHOOTING', 'UPLOADING', req.user!.partnerId!);
  emitToBooking(req.params.id, SOCKET_EVENTS.SHOOTING_COMPLETED, { bookingId: req.params.id });

  res.json({ success: true });
});

// ── POST /api/bookings/:id/cancel — Cancellation with policy ─────────────────
router.post('/:id/cancel', authenticate, async (req, res) => {
  const booking = await prisma.booking.findUnique({
    where: { id: req.params.id },
    include: { partner: true },
  });
  if (!booking) { res.status(404).json({ error: 'Booking not found' }); return; }

  // Authorization check
  const isClient = req.user!.role === 'CLIENT' && booking.userId === req.user!.id;
  const isPartner = req.user!.role === 'PARTNER' && booking.partnerId === req.user!.partnerId;
  const isAdmin = ['ADMIN', 'SUPER_ADMIN'].includes(req.user!.role);
  if (!isClient && !isPartner && !isAdmin) {
    res.status(403).json({ error: 'Not authorized to cancel this booking' }); return;
  }

  // Cancellation policy (backend-enforced)
  const CANCELLABLE_STATUSES = ['PENDING_PAYMENT', 'PAID', 'DISPATCHING', 'PARTNER_OFFERED', 'PARTNER_ASSIGNED', 'EN_ROUTE'];
  const CANCELLABLE_WITH_FEE = ['ARRIVED'];
  const NOT_CANCELLABLE = ['SHOOTING', 'UPLOADING', 'SYNCED', 'EDITING', 'QUALITY_CHECK', 'DELIVERED', 'PAYOUT_COMPLETED'];

  let canCancel = false;
  let cancellationFee = 0;
  let reason = '';

  if (CANCELLABLE_STATUSES.includes(booking.status)) {
    canCancel = true;
  } else if (CANCELLABLE_WITH_FEE.includes(booking.status)) {
    canCancel = true;
    cancellationFee = isClient ? 20000 : 0; // ₹200 fee if partner already arrived
    reason = 'Cancellation fee applies as partner has arrived';
  } else if (NOT_CANCELLABLE.includes(booking.status)) {
    res.status(400).json({
      canCancel: false,
      error: 'Cancellation not available at this stage',
      status: booking.status,
    });
    return;
  }

  if (!canCancel) { res.status(400).json({ error: 'Cannot cancel booking', status: booking.status }); return; }

  await prisma.booking.update({
    where: { id: req.params.id },
    data: {
      status: 'CANCELLED',
      cancelledAt: new Date(),
      cancelledBy: req.user!.role,
      cancellationReason: req.body.reason || reason,
      cancellationFee,
    },
  });

  // Release partner if assigned
  if (booking.partnerId) {
    await prisma.partner.update({
      where: { id: booking.partnerId },
      data: { isAvailable: true },
    });
    await setPartnerAvailable(booking.partnerId);
    emitToPartner(booking.partnerId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: booking.id, status: 'CANCELLED' });
  }

  emitToBooking(booking.id, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: booking.id, status: 'CANCELLED' });
  emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, { bookingId: booking.id, status: 'CANCELLED', cancellationFee });

  res.json({ success: true, canCancel: true, cancellationFee });
});

export default router;
