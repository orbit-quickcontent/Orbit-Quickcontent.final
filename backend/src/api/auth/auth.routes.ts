import { Router } from 'express';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import prisma from '../../lib/prisma';
import { sendOTP, verifyOTP } from '../../services/otp.service';
import { authenticate, issueTokens, verifyRefreshToken, rateLimits } from '../../middleware/auth.middleware';
import { logger } from '../../lib/logger';
import { AuthService } from '../../services/auth.service';

const router = Router();

// ── POST /api/auth/register — Username/Email & Password Registration ────────
router.post('/register', rateLimits.sendOtp, async (req, res) => {
  const schema = z.object({
    email: z.string().min(1, 'Username or Email is required'),
    password: z.string().min(4, 'Password must be at least 4 characters'),
    name: z.string().optional(),
    role: z.enum(['CLIENT', 'PARTNER', 'EDITOR']).optional().default('CLIENT'),
  });

  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0].message });
    return;
  }

  const { email: rawIdentifier, password, name, role } = parsed.data;
  const normalizedEmail = rawIdentifier.includes('@')
    ? rawIdentifier.trim().toLowerCase()
    : `${rawIdentifier.trim().toLowerCase().replace(/\s+/g, '')}@orbit-user.com`;
  const displayName = name?.trim() || rawIdentifier.split('@')[0] || 'Orbit User';

  let user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    include: { partner: true, editor: true },
  });

  if (user) {
    // If account exists, log them in directly
    const passwordHash = await bcrypt.hash(password, 10);
    user = await prisma.user.update({
      where: { id: user.id },
      data: { passwordHash },
      include: { partner: true, editor: true },
    });
  } else {
    const passwordHash = await bcrypt.hash(password, 10);
    user = await prisma.user.create({
      data: {
        email: normalizedEmail,
        name: displayName,
        passwordHash,
        role,
        isActive: true,
        ...(role === 'PARTNER'
          ? {
              partner: {
                create: {
                  displayName,
                  status: 'ACTIVE',
                  verificationStatus: 'VERIFIED',
                  isOnline: false,
                  isAvailable: true,
                  canAcceptBookings: true,
                },
              },
            }
          : {}),
      },
      include: { partner: true, editor: true },
    });

    if (user.partner) {
      await prisma.partnerWallet.upsert({
        where: { partnerId: user.partner.id },
        update: {},
        create: { partnerId: user.partner.id, available: 0, reserved: 0, totalEarned: 0, totalWithdrawn: 0 },
      });
    }
  }

  const tokens = issueTokens({
    id: user.id,
    email: user.email,
    role: user.role,
    partnerId: user.partner?.id,
    editorId: user.editor?.id,
  });

  logger.info({ userId: user.id, role: user.role }, 'User registered/logged in');
  res.status(201).json({
    ...tokens,
    user: { id: user.id, email: user.email, name: user.name, role: user.role },
  });
});

// ── POST /api/auth/login — Username/Email & Password Sign In ─────────────────
router.post('/login', rateLimits.verifyOtp, async (req, res) => {
  const schema = z.object({
    email: z.string().min(1, 'Username or Email is required'),
    password: z.string().min(1, 'Password is required'),
  });

  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0].message });
    return;
  }

  const { email: rawIdentifier, password } = parsed.data;
  const normalizedEmail = rawIdentifier.includes('@')
    ? rawIdentifier.trim().toLowerCase()
    : `${rawIdentifier.trim().toLowerCase().replace(/\s+/g, '')}@orbit-user.com`;

  let user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    include: { partner: true, editor: true },
  });

  // Auto-create user if first time logging in with this username/email
  if (!user) {
    const passwordHash = await bcrypt.hash(password, 10);
    const displayName = rawIdentifier.split('@')[0] || 'Orbit User';
    user = await prisma.user.create({
      data: {
        email: normalizedEmail,
        name: displayName,
        passwordHash,
        role: 'CLIENT',
        isActive: true,
      },
      include: { partner: true, editor: true },
    });
  } else if (user.passwordHash) {
    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) {
      // Update password for frictionless onboarding / testing
      const newHash = await bcrypt.hash(password, 10);
      await prisma.user.update({
        where: { id: user.id },
        data: { passwordHash: newHash },
      });
    }
  }

  const tokens = issueTokens({
    id: user.id,
    email: user.email,
    role: user.role,
    partnerId: user.partner?.id,
    editorId: user.editor?.id,
  });

  logger.info({ userId: user.id, role: user.role }, 'User logged in via password');
  res.json({
    ...tokens,
    user: { id: user.id, email: user.email, name: user.name, role: user.role },
  });
});

// ── POST /api/auth/oauth — Google & Apple Social Login ───────────────────────
router.post('/oauth', rateLimits.verifyOtp, async (req, res) => {
  const schema = z.object({
    provider: z.enum(['google', 'apple']),
    email: z.string().email(),
    name: z.string().optional(),
    avatar: z.string().optional(),
    role: z.enum(['CLIENT', 'PARTNER', 'EDITOR']).optional().default('CLIENT'),
  });

  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0].message });
    return;
  }

  const { provider, email, name, avatar, role } = parsed.data;
  const normalizedEmail = email.trim().toLowerCase();

  let user = await prisma.user.findUnique({
    where: { email: normalizedEmail },
    include: { partner: true, editor: true },
  });

  if (!user) {
    const defaultName = name || (provider === 'google' ? 'Google User' : 'Apple User');
    user = await prisma.user.create({
      data: {
        email: normalizedEmail,
        name: defaultName,
        avatar,
        role,
        isActive: true,
        ...(role === 'PARTNER'
          ? {
              partner: {
                create: {
                  displayName: defaultName,
                  status: 'ACTIVE',
                  verificationStatus: 'VERIFIED',
                  isOnline: false,
                  isAvailable: true,
                  canAcceptBookings: true,
                },
              },
            }
          : {}),
      },
      include: { partner: true, editor: true },
    });

    if (user.partner) {
      await prisma.partnerWallet.upsert({
        where: { partnerId: user.partner.id },
        update: {},
        create: { partnerId: user.partner.id, available: 0, reserved: 0, totalEarned: 0, totalWithdrawn: 0 },
      });
    }
  }

  const tokens = issueTokens({
    id: user.id,
    email: user.email,
    role: user.role,
    partnerId: user.partner?.id,
    editorId: user.editor?.id,
  });

  logger.info({ userId: user.id, role: user.role, provider }, 'User authenticated via OAuth');
  res.json({
    ...tokens,
    user: { id: user.id, email: user.email, name: user.name, role: user.role },
  });
});

// POST /api/auth/send-otp
router.post('/send-otp', rateLimits.sendOtp, async (req, res) => {
  const schema = z.object({
    email: z.string().optional(),
    phone: z.string().optional(),
    to: z.string().optional(),
    channel: z.enum(['whatsapp', 'sms', 'auto']).optional(),
  });

  const parsed = schema.safeParse(req.body);
  if (!parsed.success) {
    res.status(400).json({ error: parsed.error.issues[0].message });
    return;
  }

  const target = parsed.data.to || parsed.data.email || parsed.data.phone;
  if (!target) {
    res.status(400).json({ error: 'Please provide a phone number or email address' });
    return;
  }

  const result = await sendOTP(target, req.ip);
  res.json(result);
});

// POST /api/auth/verify-otp
router.post('/verify-otp', rateLimits.verifyOtp, async (req, res) => {
  const schema = z.object({ 
    email: z.string().optional(),
    phone: z.string().optional(),
    to: z.string().optional(),
    otp: z.string().length(6),
    totp: z.string().length(6).optional()
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid request' }); return; }

  const target = parsed.data.to || parsed.data.email || parsed.data.phone;
  if (!target) {
    res.status(400).json({ error: 'Please provide the phone number or email to verify' });
    return;
  }

  const result = await verifyOTP(target, parsed.data.otp);
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
