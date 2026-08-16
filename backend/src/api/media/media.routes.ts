import { Router } from 'express';
import { z } from 'zod';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../../lib/prisma';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { emitToBooking, emitToAdmin, SOCKET_EVENTS } from '../../services/socket.service';
import { firebaseStorage } from '../../services/firebase-admin';
import { logger } from '../../lib/logger';

const router = Router();

// POST /api/media/upload-url — Get Firebase signed upload URL
router.post('/upload-url', authenticate, authorize('PARTNER'), async (req, res) => {
  const schema = z.object({
    bookingId: z.string(),
    fileName: z.string().max(200),
    mimeType: z.enum(['video/mp4', 'video/quicktime', 'video/x-msvideo', 'video/webm']),
    sizeBytes: z.number().max(5_368_709_120), // 5GB max
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid upload request' }); return; }

  // Verify booking belongs to this partner
  const booking = await prisma.booking.findUnique({
    where: { id: parsed.data.bookingId, partnerId: req.user!.partnerId },
  });
  if (!booking || !['UPLOADING'].includes(booking.status)) {
    res.status(403).json({ error: 'Not authorized to upload for this booking' }); return;
  }

  const key = `raw/${parsed.data.bookingId}/${uuidv4()}-${parsed.data.fileName}`;

  try {
    const bucket = firebaseStorage.bucket();
    const file = bucket.file(key);
    const [signedUrl] = await file.getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + 15 * 60 * 1000,
      contentType: parsed.data.mimeType,
    });

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${key}`;

    // Pre-create media asset record
    const asset = await prisma.mediaAsset.create({
      data: {
        bookingId: parsed.data.bookingId,
        type: 'RAW_FOOTAGE',
        url: publicUrl,
        key,
        mimeType: parsed.data.mimeType,
        sizeBytes: BigInt(parsed.data.sizeBytes),
        uploadedBy: req.user!.partnerId,
        isVerified: false,
      },
    });

    res.json({ uploadUrl: signedUrl, key, assetId: asset.id, publicUrl });
  } catch (err: any) {
    logger.error({ err: err.message }, 'Failed to create Firebase Storage signed upload URL');
    res.status(500).json({ error: 'Failed to generate upload URL' });
  }
});

// POST /api/media/finalize — Partner confirms upload complete
router.post('/finalize', authenticate, authorize('PARTNER'), async (req, res) => {
  const schema = z.object({ bookingId: z.string(), assetIds: z.array(z.string()).min(1) });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid request' }); return; }

  const booking = await prisma.booking.findUnique({
    where: { id: parsed.data.bookingId, partnerId: req.user!.partnerId },
  });
  if (!booking || booking.status !== 'UPLOADING') {
    res.status(400).json({ error: 'Booking not in uploading state' }); return;
  }

  // Verify assets exist in DB
  const assets = await prisma.mediaAsset.findMany({
    where: { id: { in: parsed.data.assetIds }, bookingId: parsed.data.bookingId },
  });
  if (assets.length !== parsed.data.assetIds.length) {
    res.status(400).json({ error: 'Some asset IDs not found' }); return;
  }

  // Mark assets as verified and booking as SYNCED
  await prisma.$transaction([
    prisma.mediaAsset.updateMany({
      where: { id: { in: parsed.data.assetIds } },
      data: { isVerified: true, verifiedAt: new Date() },
    }),
    prisma.booking.update({
      where: { id: parsed.data.bookingId },
      data: { status: 'SYNCED', uploadCompletedAt: new Date(), syncPercentage: 100 },
    }),
  ]);

  emitToBooking(parsed.data.bookingId, SOCKET_EVENTS.UPLOAD_COMPLETED, { bookingId: parsed.data.bookingId });
  emitToAdmin(SOCKET_EVENTS.EDITOR_JOB_AVAILABLE, { bookingId: parsed.data.bookingId });

  // Make available for editor
  await prisma.booking.update({
    where: { id: parsed.data.bookingId },
    data: { status: 'EDITOR_AVAILABLE' },
  });

  logger.info({ bookingId: parsed.data.bookingId }, 'Footage finalized — editor notified');
  res.json({ success: true });
});

// POST /api/media/editor-upload-url — Editor uploads final reel
router.post('/editor-upload-url', authenticate, authorize('EDITOR'), async (req, res) => {
  const schema = z.object({
    bookingId: z.string(),
    fileName: z.string().max(200),
    mimeType: z.string(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid request' }); return; }

  const booking = await prisma.booking.findUnique({
    where: { id: parsed.data.bookingId, editorId: req.user!.editorId },
  });
  if (!booking || !['EDITING'].includes(booking.status)) {
    res.status(403).json({ error: 'Not authorized to upload for this booking' }); return;
  }

  const key = `reels/${parsed.data.bookingId}/${uuidv4()}-${parsed.data.fileName}`;

  try {
    const bucket = firebaseStorage.bucket();
    const file = bucket.file(key);
    const [signedUrl] = await file.getSignedUrl({
      version: 'v4',
      action: 'write',
      expires: Date.now() + 15 * 60 * 1000,
      contentType: parsed.data.mimeType,
    });

    const publicUrl = `https://storage.googleapis.com/${bucket.name}/${key}`;

    res.json({ uploadUrl: signedUrl, key, publicUrl });
  } catch (err: any) {
    logger.error({ err: err.message }, 'Failed to create Firebase Storage signed upload URL for editor');
    res.status(500).json({ error: 'Failed to generate upload URL' });
  }
});

export default router;
