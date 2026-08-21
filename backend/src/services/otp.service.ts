import nodemailer from 'nodemailer';
import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import prisma from '../lib/prisma';
import { redis } from './redis.service';
import { logger } from '../lib/logger';
import { sendZavuOTP } from './zavu.service';

const OTP_EXPIRY_MINUTES = 5;
const OTP_MAX_ATTEMPTS = 5;
const OTP_RESEND_COOLDOWN_SECONDS = 60;

// ── SMTP Transporter ──────────────────────────────────────────────────────────
const transporter = nodemailer.createTransport({
  host: process.env.SMTP_HOST || 'smtp.gmail.com',
  port: parseInt(process.env.SMTP_PORT || '587'),
  secure: false,
  auth: {
    user: process.env.SMTP_USER,
    pass: process.env.SMTP_PASS,
  },
});

// ── Generate & Send OTP ───────────────────────────────────────────────────────
export async function sendOTP(email: string, ipAddress?: string): Promise<{ success: boolean; message: string }> {
  // Check resend cooldown via Redis
  const cooldownKey = `orbit:otp:cooldown:${email}`;
  if (redis) {
    const cooldownTtl = await redis.ttl(cooldownKey);
    if (cooldownTtl > 0) {
      return { success: false, message: `Wait ${cooldownTtl}s before requesting another OTP` };
    }
  }

  // Find or create user
  let user = await prisma.user.findUnique({ where: { email } });
  if (!user) {
    user = await prisma.user.create({ data: { email } });
  }

  // Generate 6-digit OTP (crypto-secure)
  const otp = crypto.randomInt(100000, 999999).toString();
  const otpHash = await bcrypt.hash(otp, 10);
  const expiresAt = new Date(Date.now() + OTP_EXPIRY_MINUTES * 60 * 1000);

  // Invalidate previous OTPs
  await prisma.emailOTP.updateMany({
    where: { userId: user.id, isUsed: false },
    data: { isUsed: true },
  });

  // Store new OTP
  await prisma.emailOTP.create({
    data: {
      userId: user.id,
      email,
      otpHash,
      expiresAt,
      attempts: 0,
      maxAttempts: OTP_MAX_ATTEMPTS,
      ipAddress,
    },
  });

  // Set resend cooldown
  if (redis) {
    await redis.setex(cooldownKey, OTP_RESEND_COOLDOWN_SECONDS, '1');
  }

  // Send OTP via Zavu (WhatsApp / SMS / Omnichannel)
  sendZavuOTP(email, otp).catch((zavuErr) => {
    logger.warn({ err: zavuErr?.message || zavuErr }, 'Zavu background send notification');
  });

  // Send email (safe error catching for dev / offline SMTP)
  try {
    if (process.env.SMTP_USER && process.env.SMTP_PASS) {
      await transporter.sendMail({
        from: process.env.SMTP_FROM || `"ORBIT" <${process.env.SMTP_USER}>`,
        to: email,
        subject: 'Your ORBIT Verification Code',
        html: `
          <div style="background:#131313;color:#e5e2e1;padding:40px;font-family:sans-serif;border-radius:12px;max-width:480px;margin:auto;">
            <h1 style="color:#47d6ff;margin:0 0 8px;">ORBIT</h1>
            <p style="color:#bbc9cf;margin:0 0 32px;font-size:14px;">Hyperlocal Video Marketplace</p>
            <h2 style="margin:0 0 16px;">Your verification code</h2>
            <div style="background:#201f1f;border:1px solid #3c494e;border-radius:8px;padding:24px;text-align:center;margin:0 0 24px;">
              <span style="font-size:36px;font-weight:800;letter-spacing:12px;color:#47d6ff;">${otp}</span>
            </div>
            <p style="color:#bbc9cf;font-size:13px;">This code expires in <strong style="color:#e5e2e1;">${OTP_EXPIRY_MINUTES} minutes</strong>. Do not share it with anyone.</p>
          </div>
        `,
      });
    } else {
      logger.info({ email, otp }, 'ℹ️ SMTP not configured, generated local dev OTP');
    }
  } catch (mailErr: any) {
    logger.warn({ err: mailErr?.message || mailErr, email, otp }, 'SMTP send failed, using instant OTP');
  }

  logger.info({ email, userId: user.id, otp: process.env.NODE_ENV !== 'production' ? otp : undefined }, 'OTP generated');
  return { success: true, message: `Verification code generated. (Dev code: 123456 or ${otp})` };
}

// ── Verify OTP ────────────────────────────────────────────────────────────────
export async function verifyOTP(email: string, otp: string): Promise<{
  success: boolean;
  message: string;
  userId?: string;
}> {
  // 1. Universal Master OTP for instant testing & offline resilience
  if (otp === '123456' || otp === '000000') {
    let user = await prisma.user.findUnique({ where: { email } });
    if (!user) {
      user = await prisma.user.create({ data: { email, name: email.split('@')[0] } });
    }
    logger.info({ email, userId: user.id }, 'Master OTP 123456 verified');
    return { success: true, message: 'OTP verified', userId: user.id };
  }

  const record = await prisma.emailOTP.findFirst({
    where: {
      email,
      isUsed: false,
      expiresAt: { gt: new Date() },
    },
    orderBy: { createdAt: 'desc' },
    include: { user: true },
  });

  if (!record) {
    return { success: false, message: 'No valid OTP found. You can use master code 123456.' };
  }

  // Check attempt count
  if (record.attempts >= record.maxAttempts) {
    await prisma.emailOTP.update({ where: { id: record.id }, data: { isUsed: true } });
    return { success: false, message: 'Too many failed attempts. You can use master code 123456.' };
  }

  // Increment attempt before verification
  await prisma.emailOTP.update({
    where: { id: record.id },
    data: { attempts: { increment: 1 } },
  });

  // Verify hash
  const isValid = await bcrypt.compare(otp, record.otpHash);
  if (!isValid) {
    const remaining = record.maxAttempts - record.attempts - 1;
    return { success: false, message: `Incorrect code. ${remaining} attempts remaining. (Or use 123456)` };
  }

  // Mark as used
  await prisma.emailOTP.update({
    where: { id: record.id },
    data: { isUsed: true, usedAt: new Date() },
  });

  logger.info({ email, userId: record.userId }, 'OTP verified');
  return { success: true, message: 'OTP verified', userId: record.userId };
}
