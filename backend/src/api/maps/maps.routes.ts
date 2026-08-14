import { Router } from 'express';
import { z } from 'zod';
import { getRoute } from '../../services/maps.service';
import { updatePartnerLocation } from '../../services/redis.service';
import { emitToBooking, SOCKET_EVENTS } from '../../services/socket.service';
import { authenticate, authorize, rateLimits } from '../../middleware/auth.middleware';
import prisma from '../../lib/prisma';

const router = Router();

// GET /api/maps/route?originLat=&originLng=&destLat=&destLng=
router.get('/route', authenticate, async (req, res) => {
  const schema = z.object({
    originLat: z.coerce.number().min(-90).max(90),
    originLng: z.coerce.number().min(-180).max(180),
    destLat: z.coerce.number().min(-90).max(90),
    destLng: z.coerce.number().min(-180).max(180),
  });
  const parsed = schema.safeParse(req.query);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid coordinates' }); return; }

  const route = await getRoute(
    parsed.data.originLat, parsed.data.originLng,
    parsed.data.destLat, parsed.data.destLng
  );

  if (!route) { res.status(503).json({ error: 'Route service unavailable' }); return; }
  res.json(route);
});

// POST /api/location/update — Partner GPS update
router.post('/update', authenticate, authorize('PARTNER'), rateLimits.locationUpdate, async (req, res) => {
  const schema = z.object({
    bookingId: z.string().optional(),
    latitude: z.number().min(-90).max(90),
    longitude: z.number().min(-180).max(180),
    accuracy: z.number().optional(),
    heading: z.number().optional(),
    speed: z.number().optional(),
  });
  const parsed = schema.safeParse(req.body);
  if (!parsed.success) { res.status(400).json({ error: 'Invalid location data' }); return; }

  const partnerId = req.user!.partnerId!;
  const { latitude, longitude, accuracy, heading, speed, bookingId } = parsed.data;

  // Update Redis GEO
  await updatePartnerLocation(partnerId, latitude, longitude, {
    accuracy: accuracy?.toString() || '0',
    heading: heading?.toString() || '0',
    speed: speed?.toString() || '0',
  });

  // Update DB (less frequently via throttling on client side)
  await prisma.partner.update({
    where: { id: partnerId },
    data: { latitude, longitude, lastSeenAt: new Date() },
  });

  // Emit live location to booking room if active
  if (bookingId) {
    emitToBooking(bookingId, SOCKET_EVENTS.PARTNER_LOCATION, {
      partnerId,
      latitude,
      longitude,
      accuracy,
      heading,
      speed,
      timestamp: new Date().toISOString(),
    });
  }

  res.json({ success: true });
});

export default router;
