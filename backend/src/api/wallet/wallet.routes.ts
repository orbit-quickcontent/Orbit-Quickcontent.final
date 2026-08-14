import { Router } from 'express';
import { z } from 'zod';
import prisma from '../../lib/prisma';
import { authenticate, authorize, rateLimits } from '../../middleware/auth.middleware';
import { initiateWithdrawal } from '../../services/wallet.service';

const router = Router();

// GET /api/wallet — Get partner wallet
router.get('/', authenticate, authorize('PARTNER'), async (req, res) => {
  let wallet = await prisma.partnerWallet.findUnique({
    where: { partnerId: req.user!.partnerId! },
  });
  if (!wallet) {
    wallet = await prisma.partnerWallet.create({
      data: { partnerId: req.user!.partnerId!, available: 0, reserved: 0, totalEarned: 0, totalWithdrawn: 0 },
    });
  }
  res.json({
    available: wallet.available / 100,
    reserved: wallet.reserved / 100,
    totalEarned: wallet.totalEarned / 100,
    totalWithdrawn: wallet.totalWithdrawn / 100,
  });
});

// GET /api/wallet/transactions
router.get('/transactions', authenticate, authorize('PARTNER'), async (req, res) => {
  const { page = '1', limit = '20' } = req.query;
  const skip = (parseInt(page as string) - 1) * parseInt(limit as string);

  const [transactions, total] = await Promise.all([
    prisma.walletTransaction.findMany({
      where: { partnerId: req.user!.partnerId! },
      orderBy: { createdAt: 'desc' },
      skip,
      take: parseInt(limit as string),
    }),
    prisma.walletTransaction.count({ where: { partnerId: req.user!.partnerId! } }),
  ]);

  res.json({
    transactions: transactions.map(t => ({
      ...t,
      amount: t.amount / 100,
      balanceAfter: t.balanceAfter / 100,
    })),
    total,
  });
});

// POST /api/wallet/withdraw
router.post('/withdraw', authenticate, authorize('PARTNER'), rateLimits.withdraw, async (req, res) => {
  const schema = z.object({
    amount: z.number().min(100).max(50000),
    bankAccountId: z.string(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: parsed.error.issues[0].message }); return; }

  const result = await initiateWithdrawal(
    req.user!.partnerId!,
    parsed.data.amount,
    parsed.data.bankAccountId
  );

  if (!result.success) { res.status(400).json(result); return; }
  res.json(result);
});

// GET /api/wallet/withdrawals
router.get('/withdrawals', authenticate, authorize('PARTNER'), async (req, res) => {
  const withdrawals = await prisma.withdrawal.findMany({
    where: { partnerId: req.user!.partnerId! },
    include: { bankAccount: { select: { accountHolderName: true, ifscCode: true, bankName: true } } },
    orderBy: { requestedAt: 'desc' },
    take: 50,
  });

  res.json(withdrawals.map(w => ({
    ...w,
    amount: w.amount / 100,
  })));
});

export default router;
