import { Router } from 'express';
import { z } from 'zod';
import prisma from '../../lib/prisma';
import { sendOTP, verifyOTP } from '../../services/otp.service';
import { authenticate, issueTokens, verifyRefreshToken, rateLimits } from '../../middleware/auth.middleware';
import { logger } from '../../lib/logger';

const router = Router();

// POST /api/auth/send-otp
router.post('/send-otp', rateLimits.sendOtp, async (req, res) => {
  const schema = z.object({ email: z.string().email() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.issues[0].message }); return; }

  const result = await sendOTP(parsed.data.email, req.ip);
  res.json(result);
});

// POST /api/auth/verify-otp
router.post('/verify-otp', rateLimits.verifyOtp, async (req, res) => {
  const schema = z.object({ email: z.string().email(), otp: z.string().length(6) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid request' }); return; }

  const result = await verifyOTP(parsed.data.email, parsed.data.otp);
  if (!result.success) { res.status(400).json(result); return; }

  const user = await prisma.user.findUnique({
    where: { id: result.userId! },
    include: { partner: true, editor: true },
  });
  if (!user) { res.status(404).json({ error: 'User not found' }); return; }

  const tokens = issueTokens({
    id: user.id,
    email: user.email,
    role: user.role,
    partnerId: user.partner?.id,
    editorId: user.editor?.id,
  });

  logger.info({ userId: user.id, role: user.role }, 'User logged in via OTP');
  res.json({ ...tokens, user: { id: user.id, email: user.email, name: user.name, role: user.role } });
});

// POST /api/auth/refresh
router.post('/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) { res.status(400).json({ error: 'Refresh token required' }); return; }

  const payload = verifyRefreshToken(refreshToken);
  if (!payload) { res.status(401).json({ error: 'Invalid or expired refresh token' }); return; }

  const user = await prisma.user.findUnique({
    where: { id: payload.id },
    include: { partner: true, editor: true },
  });
  if (!user || !user.isActive) { res.status(401).json({ error: 'Account not found or inactive' }); return; }

  const tokens = issueTokens({
    id: user.id,
    email: user.email,
    role: user.role,
    partnerId: user.partner?.id,
    editorId: user.editor?.id,
  });

  res.json(tokens);
});

// GET /api/auth/me
router.get('/me', authenticate, async (req, res) => {
  const user = await prisma.user.findUnique({
    where: { id: req.user!.id },
    select: { id: true, email: true, name: true, phone: true, role: true, avatar: true, createdAt: true },
  });
  res.json(user);
});

// POST /api/auth/logout (client-side token removal; FCM token cleanup)
router.post('/logout', authenticate, async (req, res) => {
  const { fcmToken } = req.body;
  if (fcmToken) {
    await prisma.user.update({
      where: { id: req.user!.id },
      data: { fcmToken: null },
    });
  }
  res.json({ success: true });
});

export default router;
