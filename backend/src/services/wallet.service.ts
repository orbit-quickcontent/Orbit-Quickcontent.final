import prisma from '../lib/prisma';
import { emitToPartner, SOCKET_EVENTS } from './socket.service';
import { sendBookingNotification } from './fcm.service';
import { logger } from '../lib/logger';

const PARTNER_EARNING_PAISE = parseInt(process.env.PARTNER_EARNING_AMOUNT || '500', 10) * 100;

// ── Credit ₹500 to Partner Wallet (Idempotent) ─────────────────────────────────
export async function creditPartnerEarning(bookingId: string, partnerId: string): Promise<{
  success: boolean;
  alreadyCredited?: boolean;
}> {
  const idempotencyKey = `booking_earning_${bookingId}`;

  // Check if already credited (idempotency)
  const existing = await prisma.walletTransaction.findUnique({
    where: { idempotencyKey },
  });
  if (existing) {
    logger.warn({ bookingId, partnerId }, 'Wallet credit already processed (idempotent skip)');
    return { success: true, alreadyCredited: true };
  }

  // Get or create wallet
  let wallet = await prisma.partnerWallet.findUnique({ where: { partnerId } });
  if (!wallet) {
    wallet = await prisma.partnerWallet.create({
      data: { partnerId, available: 0, reserved: 0, totalEarned: 0, totalWithdrawn: 0 },
    });
  }

  // Credit in transaction
  await prisma.$transaction(async (tx) => {
    const updatedWallet = await tx.partnerWallet.update({
      where: { partnerId },
      data: {
        available: { increment: PARTNER_EARNING_PAISE },
        totalEarned: { increment: PARTNER_EARNING_PAISE },
      },
    });

    await tx.walletTransaction.create({
      data: {
        partnerId,
        walletId: wallet!.id,
        bookingId,
        type: 'EARNING',
        amount: PARTNER_EARNING_PAISE,
        balanceAfter: updatedWallet.available,
        status: 'COMPLETED',
        description: `Booking #${bookingId} completion earning`,
        idempotencyKey,
      },
    });

    await tx.booking.update({
      where: { id: bookingId },
      data: { status: 'PAYOUT_COMPLETED' },
    });
  });

  // Notify partner
  emitToPartner(partnerId, SOCKET_EVENTS.WALLET_CREDITED, {
    amount: PARTNER_EARNING_PAISE / 100,
    bookingId,
  });

  const partner = await prisma.partner.findUnique({
    where: { id: partnerId },
    select: { fcmToken: true },
  });
  if (partner?.fcmToken) {
    await sendBookingNotification(partner.fcmToken, {
      title: '💰 ₹500 Credited!',
      body: 'Your earnings from the completed booking have been credited to your ORBIT wallet.',
      data: { type: 'WALLET_CREDITED', bookingId, amount: '500' },
    });
  }

  logger.info({ bookingId, partnerId, amount: PARTNER_EARNING_PAISE }, '✅ Partner earning credited');
  return { success: true };
}

// ── Initiate Withdrawal ───────────────────────────────────────────────────────
export async function initiateWithdrawal(partnerId: string, amountINR: number, bankAccountId: string): Promise<{
  success: boolean;
  message: string;
  withdrawalId?: string;
}> {
  const amountPaise = amountINR * 100;
  const wallet = await prisma.partnerWallet.findUnique({ where: { partnerId } });

  if (!wallet) return { success: false, message: 'Wallet not found' };
  if (wallet.available < amountPaise) {
    return { success: false, message: `Insufficient balance. Available: ₹${wallet.available / 100}` };
  }
  if (amountINR < 100) return { success: false, message: 'Minimum withdrawal is ₹100' };

  const bankAccount = await prisma.bankAccount.findFirst({
    where: { id: bankAccountId, partnerId, isActive: true, verificationStatus: 'VERIFIED' },
  });
  if (!bankAccount) return { success: false, message: 'Bank account not found or not verified' };

  const idempotencyKey = `withdrawal_${partnerId}_${Date.now()}`;

  // Reserve amount and create withdrawal record
  const [, withdrawal] = await prisma.$transaction([
    prisma.partnerWallet.update({
      where: { partnerId },
      data: {
        available: { decrement: amountPaise },
        reserved: { increment: amountPaise },
      },
    }),
    prisma.withdrawal.create({
      data: {
        partnerId,
        walletId: wallet.id,
        bankAccountId,
        amount: amountPaise,
        status: 'REQUESTED',
        idempotencyKey,
      },
    }),
  ]);

  // Dispatch to Cashfree via BullMQ worker
  const { payoutQueue } = await import('./queue.service');
  await payoutQueue.add('process-payout', {
    withdrawalId: withdrawal.id,
    partnerId,
    amountPaise,
    bankAccountId,
  }, { jobId: withdrawal.id });

  logger.info({ partnerId, withdrawalId: withdrawal.id, amountINR }, 'Withdrawal initiated');
  return { success: true, message: 'Withdrawal initiated', withdrawalId: withdrawal.id };
}

// ── Handle Cashfree Webhook ───────────────────────────────────────────────────
export async function handleCashfreeWebhook(withdrawalId: string, status: string, data: any) {
  const withdrawal = await prisma.withdrawal.findUnique({ where: { id: withdrawalId } });
  if (!withdrawal) return;

  // Idempotency: skip if already in final state
  if (['COMPLETED', 'FAILED'].includes(withdrawal.status)) {
    logger.warn({ withdrawalId }, 'Duplicate payout webhook — ignoring');
    return;
  }

  await prisma.$transaction(async (tx) => {
    if (status === 'SUCCESS') {
      await tx.withdrawal.update({
        where: { id: withdrawalId },
        data: { status: 'COMPLETED', completedAt: new Date(), webhookData: data },
      });

      // Deduct from reserved (not available — already deducted on initiation)
      await tx.partnerWallet.update({
        where: { partnerId: withdrawal.partnerId },
        data: {
          reserved: { decrement: withdrawal.amount },
          totalWithdrawn: { increment: withdrawal.amount },
        },
      });

      await tx.walletTransaction.create({
        data: {
          partnerId: withdrawal.partnerId,
          walletId: withdrawal.walletId,
          withdrawalId: withdrawal.id,
          type: 'WITHDRAWAL',
          amount: -withdrawal.amount,
          balanceAfter: 0, // Will be updated below
          status: 'COMPLETED',
          description: 'Bank withdrawal completed',
          idempotencyKey: `withdrawal_complete_${withdrawalId}`,
        },
      });

      emitToPartner(withdrawal.partnerId, SOCKET_EVENTS.PAYOUT_COMPLETED, {
        withdrawalId,
        amount: withdrawal.amount / 100,
      });
    } else if (['FAILED', 'CANCELLED', 'REVERSED'].includes(status)) {
      // Release reserved amount back to available
      await tx.withdrawal.update({
        where: { id: withdrawalId },
        data: { status: 'FAILED', failedAt: new Date(), failureReason: data?.reason, webhookData: data },
      });

      await tx.partnerWallet.update({
        where: { partnerId: withdrawal.partnerId },
        data: {
          available: { increment: withdrawal.amount },
          reserved: { decrement: withdrawal.amount },
        },
      });

      emitToPartner(withdrawal.partnerId, SOCKET_EVENTS.PAYOUT_FAILED, {
        withdrawalId,
        reason: data?.reason,
      });
    }
  });

  logger.info({ withdrawalId, status }, 'Cashfree webhook processed');
}
