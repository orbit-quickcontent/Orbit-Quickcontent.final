import { Router } from 'express';
import { z } from 'zod';
import prisma from '../../lib/prisma';
import { authenticate, authorize, rateLimits, issueTokens } from '../../middleware/auth.middleware';
import { verifyPartnerCode } from '../../services/verification.service';
import {
  updatePartnerLocation,
  setPartnerOnline,
  setPartnerOffline,
  setPartnerAvailable,
} from '../../services/redis.service';
import { emitToAdmin } from '../../services/socket.service';
import { logger } from '../../lib/logger';

const router = Router();

// POST /api/partner/verify-code — Two-tier verification step
router.post('/verify-code', authenticate, rateLimits.verifyCode, async (req, res) => {
  const schema = z.object({ code: z.string().min(6).max(20) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid code format' }); return; }

  const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
  if (!user) { res.status(404).json({ error: 'User not found' }); return; }

  const result = await verifyPartnerCode({
    email: user.email,
    code: parsed.data.code,
    ipAddress: req.ip,
  });

  if (!result.success) { res.status(400).json(result); return; }

  // Re-issue JWT with updated partner context
  const updatedUser = await prisma.user.findUnique({
    where: { id: req.user!.id },
    include: { partner: true },
  });
  if (!updatedUser) { res.status(500).json({ error: 'Failed to reload user' }); return; }

  const tokens = issueTokens({
    id: updatedUser.id,
    email: updatedUser.email,
    role: updatedUser.role,
    partnerId: updatedUser.partner?.id,
  });

  res.json({ ...result, ...tokens });
});

// GET /api/partner/profile
router.get('/profile', authenticate, async (req, res) => {
  const partner = await prisma.partner.findUnique({
    where: { userId: req.user!.id },
    include: { wallet: true, bankAccount: { where: { isDefault: true, isActive: true }, take: 1 } },
  });
  if (!partner) { res.status(404).json({ error: 'Partner profile not found' }); return; }
  res.json(partner);
});

// PUT /api/partner/profile — Update profile
router.put('/profile', authenticate, authorize('PARTNER'), async (req, res) => {
  const schema = z.object({
    displayName: z.string().optional(),
    phone: z.string().optional(),
    address: z.string().optional(),
    city: z.string().optional(),
    state: z.string().optional(),
    pincode: z.string().optional(),
    experienceYears: z.number().optional(),
    equipment: z.array(z.string()).optional(),
    bio: z.string().optional(),
    fcmToken: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid data' }); return; }

  const partner = await prisma.partner.findUnique({ where: { userId: req.user!.id } });
  if (!partner) { res.status(404).json({ error: 'Partner not found' }); return; }

  const { equipment, fcmToken, ...rest } = parsed.data;
  const updated = await prisma.partner.update({
    where: { id: partner.id },
    data: {
      ...rest,
      equipment: equipment ? JSON.stringify(equipment) : undefined,
    },
  });

  // Update FCM token on User
  if (fcmToken) {
    await prisma.user.update({ where: { id: req.user!.id }, data: { fcmToken } });
    await prisma.partner.update({ where: { id: partner.id }, data: { fcmToken } });
  }

  res.json(updated);
});

// POST /api/partner/online — Go online with current location
router.post('/online', authenticate, authorize('PARTNER'), async (req, res) => {
  const schema = z.object({ latitude: z.number(), longitude: z.number() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Location required to go online' }); return; }

  const partner = await prisma.partner.findUnique({ where: { userId: req.user!.id } });
  if (!partner) { res.status(404).json({ error: 'Partner not found' }); return; }

  if (partner.status !== 'ACTIVE' || !partner.canAcceptBookings) {
    res.status(403).json({ error: 'Not authorized to go online. Complete verification first.' });
    return;
  }

  await prisma.partner.update({
    where: { id: partner.id },
    data: {
      isOnline: true,
      isAvailable: true,
      latitude: parsed.data.latitude,
      longitude: parsed.data.longitude,
      lastSeenAt: new Date(),
    },
  });

  await setPartnerOnline(partner.id, parsed.data.latitude, parsed.data.longitude);
  emitToAdmin('partner:online', { partnerId: partner.id });

  logger.info({ partnerId: partner.id }, 'Partner went online');
  res.json({ success: true, message: 'You are now online and accepting bookings' });
});

// POST /api/partner/offline — Go offline
router.post('/offline', authenticate, authorize('PARTNER'), async (req, res) => {
  const partner = await prisma.partner.findUnique({ where: { userId: req.user!.id } });
  if (!partner) { res.status(404).json({ error: 'Partner not found' }); return; }

  await prisma.partner.update({
    where: { id: partner.id },
    data: { isOnline: false, isAvailable: false },
  });

  await setPartnerOffline(partner.id);
  emitToAdmin('partner:offline', { partnerId: partner.id });

  res.json({ success: true, message: 'You are now offline' });
});

export default router;
