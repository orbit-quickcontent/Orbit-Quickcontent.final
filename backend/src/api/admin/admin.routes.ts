import { Router } from 'express';
import { z } from 'zod';
import prisma from '../../lib/prisma';
import { authenticate, authorize, rateLimits } from '../../middleware/auth.middleware';
import { createVerificationCode, revokeVerificationCode } from '../../services/verification.service';

const router = Router();

// All admin routes require ADMIN or SUPER_ADMIN role
router.use(authenticate, authorize('ADMIN', 'SUPER_ADMIN'), rateLimits.admin);

// ── Partner Codes ──────────────────────────────────────────────────────────────

// GET /api/admin/partner-codes
router.get('/partner-codes', async (req, res) => {
  const { status, email, page = '1' } = req.query;
  const skip = (parseInt(page as string) - 1) * 20;
  const where: any = {};
  if (status) where.status = status;
  if (email) where.partnerEmail = { contains: email as string, mode: 'insensitive' };

  const [codes, total] = await Promise.all([
    prisma.partnerVerificationCode.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip,
      take: 20,
      include: { partner: { include: { user: { select: { name: true, email: true } } } } },
    }),
    prisma.partnerVerificationCode.count({ where }),
  ]);

  res.json({ codes, total });
});

// POST /api/admin/partner-codes — Generate new code
router.post('/partner-codes', async (req, res) => {
  const schema = z.object({
    partnerEmail: z.string().email(),
    trainerName: z.string().min(2),
    trainingDate: z.string().datetime(),
    partnerId: z.string().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.issues[0].message }); return; }

  const result = await createVerificationCode({
    partnerEmail: parsed.data.partnerEmail,
    trainerName: parsed.data.trainerName,
    trainingDate: new Date(parsed.data.trainingDate),
    createdBy: req.user!.id,
    partnerId: parsed.data.partnerId,
  });

  res.json(result);
});

// DELETE /api/admin/partner-codes/:id — Revoke code
router.delete('/partner-codes/:id', async (req, res) => {
  const { reason } = req.body;
  await revokeVerificationCode(req.params.id, req.user!.id, reason || 'Admin revocation');
  res.json({ success: true });
});

// ── Partner Management ─────────────────────────────────────────────────────────

// GET /api/admin/partners
router.get('/partners', async (req, res) => {
  const { status, page = '1', search } = req.query;
  const skip = (parseInt(page as string) - 1) * 20;
  const where: any = {};
  if (status) where.status = status;
  if (search) {
    where.user = { OR: [{ name: { contains: search as string, mode: 'insensitive' } }, { email: { contains: search as string, mode: 'insensitive' } }] };
  }

  const [partners, total] = await Promise.all([
    prisma.partner.findMany({
      where,
      include: { user: { select: { name: true, email: true, phone: true } }, wallet: true },
      orderBy: { createdAt: 'desc' },
      skip,
      take: 20,
    }),
    prisma.partner.count({ where }),
  ]);

  res.json({ partners, total });
});

// PATCH /api/admin/partners/:id/status — Suspend/activate partner
router.patch('/partners/:id/status', async (req, res) => {
  const schema = z.object({ status: z.enum(['ACTIVE', 'SUSPENDED', 'REJECTED']), reason: z.string().optional() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid status' }); return; }

  const partner = await prisma.partner.update({
    where: { id: req.params.id },
    data: {
      status: parsed.data.status,
      isOnline: parsed.data.status === 'SUSPENDED' ? false : undefined,
      isAvailable: parsed.data.status === 'SUSPENDED' ? false : undefined,
      canAcceptBookings: parsed.data.status === 'SUSPENDED' ? false : undefined,
    },
  });

  await prisma.auditLog.create({
    data: {
      userId: req.user!.id,
      action: `PARTNER_${parsed.data.status}`,
      entity: 'Partner',
      entityId: req.params.id,
      details: { reason: parsed.data.reason },
    },
  });

  res.json(partner);
});

// ── Booking Management ─────────────────────────────────────────────────────────

// GET /api/admin/bookings
router.get('/bookings', async (req, res) => {
  const { status, page = '1' } = req.query;
  const skip = (parseInt(page as string) - 1) * 20;
  const where: any = {};
  if (status) where.status = status;

  const [bookings, total] = await Promise.all([
    prisma.booking.findMany({
      where,
      include: {
        package: true,
        user: { select: { name: true, email: true } },
        partner: { include: { user: { select: { name: true } } } },
      },
      orderBy: { createdAt: 'desc' },
      skip,
      take: 20,
    }),
    prisma.booking.count({ where }),
  ]);

  res.json({ bookings, total });
});

// ── Wallet & Withdrawals ──────────────────────────────────────────────────────

// GET /api/admin/withdrawals
router.get('/withdrawals', async (req, res) => {
  const { status, page = '1' } = req.query;
  const where: any = {};
  if (status) where.status = status;

  const [withdrawals, total] = await Promise.all([
    prisma.withdrawal.findMany({
      where,
      include: {
        partner: { include: { user: { select: { name: true, email: true } } } },
        bankAccount: { select: { accountHolderName: true, ifscCode: true, bankName: true } },
      },
      orderBy: { requestedAt: 'desc' },
      take: 50,
    }),
    prisma.withdrawal.count({ where }),
  ]);

  res.json({ withdrawals: withdrawals.map(w => ({ ...w, amount: w.amount / 100 })), total });
});

// GET /api/admin/audit-logs
router.get('/audit-logs', async (req, res) => {
  const { action, entity, page = '1' } = req.query;
  const where: any = {};
  if (action) where.action = { contains: action as string };
  if (entity) where.entity = entity;

  const logs = await prisma.auditLog.findMany({
    where,
    include: { user: { select: { name: true, email: true } } },
    orderBy: { createdAt: 'desc' },
    take: 100,
    skip: (parseInt(page as string) - 1) * 100,
  });

  res.json(logs);
});

// GET /api/admin/overview — Dashboard stats
router.get('/overview', async (_req, res) => {
  const [
    totalBookings, activeBookings, totalPartners, onlinePartners,
    totalRevenue, pendingWithdrawals,
  ] = await Promise.all([
    prisma.booking.count(),
    prisma.booking.count({ where: { status: { notIn: ['DELIVERED', 'CANCELLED', 'FAILED', 'NO_PARTNER_AVAILABLE', 'PAYOUT_COMPLETED'] } } }),
    prisma.partner.count({ where: { status: 'ACTIVE' } }),
    prisma.partner.count({ where: { isOnline: true } }),
    prisma.payment.aggregate({ where: { status: 'SUCCESS' }, _sum: { amount: true } }),
    prisma.withdrawal.count({ where: { status: 'REQUESTED' } }),
  ]);

  res.json({
    totalBookings,
    activeBookings,
    totalPartners,
    onlinePartners,
    totalRevenueINR: (totalRevenue._sum.amount || 0) / 100,
    pendingWithdrawals,
  });
});

export default router;
