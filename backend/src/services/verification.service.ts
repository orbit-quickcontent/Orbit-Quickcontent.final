import bcrypt from 'bcryptjs';
import crypto from 'crypto';
import prisma from '../lib/prisma';
import { logger } from '../lib/logger';
import { emitToAdmin } from './socket.service';

const CODE_EXPIRY_DAYS = 30;

// ── Generate Verification Code ────────────────────────────────────────────────
function generateCode(): string {
  // ORBIT-[A-Z0-9]{6} format
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude ambiguous chars
  let code = 'ORBIT-';
  const bytes = crypto.randomBytes(6);
  for (let i = 0; i < 6; i++) {
    code += chars[bytes[i] % chars.length];
  }
  return code;
}

// ── Admin: Create Partner Verification Code ───────────────────────────────────
export async function createVerificationCode(params: {
  partnerEmail: string;
  trainerName: string;
  trainingDate: Date;
  createdBy: string;
  partnerId?: string;
}): Promise<{ code: string; id: string }> {
  // Revoke any existing ACTIVE codes for this email
  await prisma.partnerVerificationCode.updateMany({
    where: { partnerEmail: params.partnerEmail, status: 'ACTIVE' },
    data: { status: 'REVOKED', revokedAt: new Date(), revocationReason: 'New code generated' },
  });

  // Generate unique code
  let code: string;
  let exists = true;
  do {
    code = generateCode();
    const found = await prisma.partnerVerificationCode.findUnique({ where: { codeHash: await bcrypt.hash(code, 10) } });
    exists = !!found;
  } while (exists);

  const codeHash = await bcrypt.hash(code, 10);
  const expiresAt = new Date(Date.now() + CODE_EXPIRY_DAYS * 24 * 60 * 60 * 1000);

  const record = await prisma.partnerVerificationCode.create({
    data: {
      code,         // Store plain for admin display
      codeHash,     // Store hash for verification
      partnerEmail: params.partnerEmail,
      partnerId: params.partnerId,
      trainerName: params.trainerName,
      trainingDate: params.trainingDate,
      expiresAt,
      status: 'ACTIVE',
      createdBy: params.createdBy,
    },
  });

  // Audit log
  await prisma.auditLog.create({
    data: {
      userId: params.createdBy,
      action: 'PARTNER_CODE_GENERATED',
      entity: 'PartnerVerificationCode',
      entityId: record.id,
      details: { partnerEmail: params.partnerEmail, trainerName: params.trainerName },
    },
  });

  // Notify admin ops room
  emitToAdmin('partner:code-generated', {
    codeId: record.id,
    partnerEmail: params.partnerEmail,
    expiresAt,
  });

  logger.info({ partnerEmail: params.partnerEmail, codeId: record.id }, 'Partner verification code generated');
  return { code, id: record.id };
}

// ── Partner: Verify Code (Two-Tier Login Step 2) ──────────────────────────────
export async function verifyPartnerCode(params: {
  email: string;
  code: string;
  ipAddress?: string;
}): Promise<{ success: boolean; message: string; partnerId?: string }> {
  // Master bypass for development/testing ONLY
  if (
    process.env.PARTNER_MASTER_LOGIN_ENABLED === 'true' &&
    params.email === process.env.PARTNER_MASTER_EMAIL &&
    params.code === process.env.PARTNER_MASTER_CODE
  ) {
    logger.warn({ email: params.email }, '⚠️  Master bypass used — not for production');
    const user = await prisma.user.findUnique({ where: { email: params.email } });
    if (!user) return { success: false, message: 'User not found' };
    const partner = await prisma.partner.findUnique({ where: { userId: user.id } });
    if (!partner) return { success: false, message: 'Partner profile not found' };
    return { success: true, message: 'Verified via master bypass', partnerId: partner.id };
  }

  // Find partner by email
  const user = await prisma.user.findUnique({ where: { email: params.email } });
  if (!user) return { success: false, message: 'No account found for this email' };

  const partner = await prisma.partner.findUnique({ where: { userId: user.id } });
  if (!partner) return { success: false, message: 'Partner profile not found' };

  // Check for suspended/rejected status
  if (partner.status === 'SUSPENDED') return { success: false, message: 'Account suspended. Contact support.' };
  if (partner.status === 'REJECTED') return { success: false, message: 'Account rejected. Contact support.' };

  // Find active code for this email
  const codeRecords = await prisma.partnerVerificationCode.findMany({
    where: { partnerEmail: params.email, status: 'ACTIVE', expiresAt: { gt: new Date() } },
    orderBy: { createdAt: 'desc' },
    take: 5,
  });

  if (codeRecords.length === 0) {
    return { success: false, message: 'No active verification code found. Contact your trainer.' };
  }

  // Find matching code (compare hash)
  let matchedRecord = null;
  for (const record of codeRecords) {
    const isMatch = await bcrypt.compare(params.code.toUpperCase().trim(), record.codeHash);
    if (isMatch) { matchedRecord = record; break; }
  }

  if (!matchedRecord) {
    await prisma.auditLog.create({
      data: {
        action: 'PARTNER_CODE_INVALID_ATTEMPT',
        entity: 'PartnerVerificationCode',
        details: { email: params.email, ipAddress: params.ipAddress },
      },
    });
    return { success: false, message: 'Invalid verification code' };
  }

  // Activate partner (transaction)
  await prisma.$transaction(async (tx) => {
    // Mark code as used
    await tx.partnerVerificationCode.update({
      where: { id: matchedRecord!.id },
      data: { status: 'USED', usedAt: new Date() },
    });

    // Activate partner
    await tx.partner.update({
      where: { id: partner.id },
      data: {
        status: 'ACTIVE',
        verificationStatus: 'VERIFIED',
        canAcceptBookings: true,
        isAvailable: false, // Must explicitly go online
      },
    });

    // Audit log
    await tx.auditLog.create({
      data: {
        userId: user.id,
        action: 'PARTNER_CODE_VERIFIED',
        entity: 'Partner',
        entityId: partner.id,
        details: { codeId: matchedRecord!.id, ipAddress: params.ipAddress },
      },
    });
  });

  logger.info({ partnerId: partner.id, email: params.email }, 'Partner verified via code');
  return { success: true, message: 'Verification successful', partnerId: partner.id };
}

// ── Admin: Revoke Code ────────────────────────────────────────────────────────
export async function revokeVerificationCode(codeId: string, revokedBy: string, reason: string) {
  await prisma.partnerVerificationCode.update({
    where: { id: codeId },
    data: { status: 'REVOKED', revokedBy, revokedAt: new Date(), revocationReason: reason },
  });

  await prisma.auditLog.create({
    data: {
      userId: revokedBy,
      action: 'PARTNER_CODE_REVOKED',
      entity: 'PartnerVerificationCode',
      entityId: codeId,
      details: { reason },
    },
  });
}
