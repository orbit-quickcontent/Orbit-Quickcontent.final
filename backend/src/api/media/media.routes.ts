import { Router } from 'express';
import { z } from 'zod';
import { createClient } from '@supabase/supabase-js';
import { v4 as uuidv4 } from 'uuid';
import prisma from '../../lib/prisma';
import { authenticate, authorize } from '../../middleware/auth.middleware';
import { emitToBooking, emitToAdmin, SOCKET_EVENTS } from '../../services/socket.service';
import { logger } from '../../lib/logger';

const router = Router();

// Supabase client (using service role for storage admin)
const getSupabaseClient = () => {
  return createClient(
    process.env.SUPABASE_URL!,
    process.env.SUPABASE_SERVICE_ROLE_KEY!
  );
};

const BUCKET_RAW = process.env.STORAGE_BUCKET_RAW || 'orbit-raw-footage';
const BUCKET_REELS = process.env.STORAGE_BUCKET_REELS || 'orbit-reels';

// POST /api/media/upload-url — Get presigned upload URL
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

  const key = `${parsed.data.bookingId}/${uuidv4()}-${parsed.data.fileName}`;
  const supabase = getSupabaseClient();

  const { data, error } = await supabase.storage.from(BUCKET_RAW).createSignedUploadUrl(key);
  
  if (error || !data) {
    logger.error({ err: error }, 'Failed to create Supabase signed upload URL');
    res.status(500).json({ error: 'Failed to generate upload URL' }); return;
  }

  const { data: publicUrlData } = supabase.storage.from(BUCKET_RAW).getPublicUrl(key);

  // Pre-create media asset record
  const asset = await prisma.mediaAsset.create({
    data: {
      bookingId: parsed.data.bookingId,
      type: 'RAW_FOOTAGE',
      url: publicUrlData.publicUrl,
      key,
      mimeType: parsed.data.mimeType,
      sizeBytes: BigInt(parsed.data.sizeBytes),
      uploadedBy: req.user!.partnerId,
      isVerified: false,
    },
  });

  res.json({ uploadUrl: data.signedUrl, key, assetId: asset.id });
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

  const key = `${parsed.data.bookingId}/${uuidv4()}-${parsed.data.fileName}`;
  const supabase = getSupabaseClient();
  const { data, error } = await supabase.storage.from(BUCKET_REELS).createSignedUploadUrl(key);

  if (error || !data) {
    logger.error({ err: error }, 'Failed to create Supabase signed upload URL');
    res.status(500).json({ error: 'Failed to generate upload URL' }); return;
  }

  const { data: publicUrlData } = supabase.storage.from(BUCKET_REELS).getPublicUrl(key);

  res.json({ uploadUrl: data.signedUrl, key, publicUrl: publicUrlData.publicUrl });
});

export default router;
