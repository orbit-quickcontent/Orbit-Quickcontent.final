import { Router } from 'express';
import { z } from 'zod';
import { getRoute, forwardGeocode, reverseGeocode } from '../../services/maps.service';
import { updatePartnerLocation } from '../../services/redis.service';
import { emitToBooking, SOCKET_EVENTS } from '../../services/socket.service';
import { authenticate, authorize, rateLimits } from '../../middleware/auth.middleware';
import prisma from '../../lib/prisma';

const router = Router();

// GET /api/maps/search?q=
router.get('/search', authenticate, async (req, res) => {
  const q = req.query.q as string;
  if (!q) { res.status(400).json({ error: 'Query parameter q is required' }); return; }
  const result = await forwardGeocode(q);
  if (!result) { res.status(404).json({ error: 'Location not found' }); return; }
  res.json(result);
});

// GET /api/maps/reverse?lat=&lng=
router.get('/reverse', authenticate, async (req, res) => {
  const lat = parseFloat(req.query.lat as string);
  const lng = parseFloat(req.query.lng as string);
  if (isNaN(lat) || isNaN(lng)) { res.status(400).json({ error: 'Valid lat and lng required' }); return; }
  const address = await reverseGeocode(lat, lng);
  res.json({ address });
});

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
