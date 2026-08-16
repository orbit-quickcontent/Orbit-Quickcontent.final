import { Router } from 'express';
import { z } from 'zod';
import prisma from '../../lib/prisma';
import { sendOTP, verifyOTP } from '../../services/otp.service';
import { authenticate, issueTokens, verifyRefreshToken, rateLimits } from '../../middleware/auth.middleware';
import { logger } from '../../lib/logger';

const router = Router();

/**
 * @swagger
 * /api/auth/send-otp:
 *   post:
 *     summary: Send OTP to email
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *     responses:
 *       200:
 *         description: OTP sent successfully
 *       400:
 *         description: Invalid email or rate limit exceeded
 */
// POST /api/auth/send-otp
router.post('/send-otp', rateLimits.sendOtp, async (req, res) => {
  const schema = z.object({ email: z.string().email() });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.issues[0].message }); return; }

  const result = await sendOTP(parsed.data.email, req.ip);
  res.json(result);
});

import { AuthService } from '../../services/auth.service';

// POST /api/auth/verify-otp
router.post('/verify-otp', rateLimits.verifyOtp, async (req, res) => {
  const schema = z.object({ 
    email: z.string().email(), 
    otp: z.string().length(6),
    totp: z.string().length(6).optional()
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid request' }); return; }

  const result = await verifyOTP(parsed.data.email, parsed.data.otp);
  if (!result.success) { res.status(400).json(result); return; }

  const user = await prisma.user.findUnique({
    where: { id: result.userId! },
    include: { partner: true, editor: true },
  });
  if (!user) { res.status(404).json({ error: 'User not found' }); return; }

  // Check 2FA if enabled
  if (user.twoFactorEnabled) {
    if (!parsed.data.totp) {
      res.status(403).json({ error: '2FA token required', requires2FA: true });
      return;
    }
    const isValid = AuthService.verifyTotpToken(parsed.data.totp, user.twoFactorSecret!);
    if (!isValid) {
      res.status(401).json({ error: 'Invalid 2FA token' });
      return;
    }
  }

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

// GET /api/auth/2fa/generate
router.get('/2fa/generate', authenticate, async (req, res) => {
  const user = await prisma.user.findUnique({ where: { id: req.user!.id } });
  if (!user) { res.status(404).json({ error: 'User not found' }); return; }
  
  const { secret, qrCodeUrl } = await AuthService.generateTotpSecret(user.email);
  res.json({ secret, qrCodeUrl });
});

// POST /api/auth/2fa/enable
router.post('/2fa/enable', authenticate, async (req, res) => {
  const schema = z.object({ secret: z.string(), token: z.string().length(6) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid request' }); return; }

  const isValid = AuthService.verifyTotpToken(parsed.data.token, parsed.data.secret);
  if (!isValid) {
    res.status(400).json({ error: 'Invalid 2FA token' });
    return;
  }

  await AuthService.enable2FA(req.user!.id, parsed.data.secret);
  res.json({ success: true });
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
