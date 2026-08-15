import prisma from '../lib/prisma';
import {
  findNearbyPartners,
  setPartnerBusy,
  REDIS_KEYS,
  redis,
} from './redis.service';
import { emitToPartner, emitToBooking, emitToClient, SOCKET_EVENTS } from './socket.service';
import { sendBookingNotification } from './fcm.service';
import { logger } from '../lib/logger';
import { BookingStatus } from '@prisma/client';

const ROUND_RADII_KM = [
  parseInt(process.env.DISPATCH_ROUND1_RADIUS_KM || '2', 10),
  parseInt(process.env.DISPATCH_ROUND2_RADIUS_KM || '5', 10),
  parseInt(process.env.DISPATCH_ROUND3_RADIUS_KM || '10', 10),
];
const OFFER_TIMEOUT = parseInt(process.env.DISPATCH_OFFER_TIMEOUT_SECONDS || '45', 10);
const PARTNER_EARNING = parseInt(process.env.PARTNER_EARNING_AMOUNT || '500', 10);

// ── Dispatch Booking to Partners ──────────────────────────────────────────────
export async function dispatchBooking(bookingId: string): Promise<boolean> {
  const booking = await prisma.booking.findUnique({
    where: { id: bookingId },
    include: { package: true, user: true },
  });

  if (!booking || !booking.latitude || !booking.longitude) {
    logger.error({ bookingId }, 'Booking not found or missing location for dispatch');
    return false;
  }

  let partnerFound = false;

  for (let round = 0; round < ROUND_RADII_KM.length; round++) {
    const radiusKm = ROUND_RADII_KM[round];
    logger.info({ bookingId, round: round + 1, radiusKm }, 'Starting dispatch round');

    // Update booking dispatch round
    await prisma.booking.update({
      where: { id: bookingId },
      data: { dispatchRound: round + 1, status: 'DISPATCHING' },
    });

    const nearbyPartners = await findNearbyPartners(
      booking.latitude,
      booking.longitude,
      radiusKm
    );

    // Filter eligible partners
    const declinedBy: string[] = (booking.declinedBy as string[]) || [];
    const eligiblePartners = [];

    for (const { id: partnerId, distanceKm } of nearbyPartners) {
      if (declinedBy.includes(partnerId)) continue;

      const partner = await prisma.partner.findUnique({
        where: { id: partnerId },
        select: {
          id: true,
          status: true,
          verificationStatus: true,
          isOnline: true,
          isAvailable: true,
          canAcceptBookings: true,
          fcmToken: true,
          userId: true,
        },
      });

      if (
        !partner ||
        partner.status !== 'ACTIVE' ||
        partner.verificationStatus !== 'VERIFIED' ||
        !partner.isOnline ||
        !partner.isAvailable ||
        !partner.canAcceptBookings
      ) continue;

      // Check not busy
      const busy = await redis.get(REDIS_KEYS.partnerBusy(partnerId));
      if (busy) continue;

      eligiblePartners.push({ partnerId, distanceKm, partner });
    }

    if (eligiblePartners.length === 0) {
      logger.info({ bookingId, round: round + 1 }, 'No eligible partners in this round');
      continue;
    }

    // Create dispatch offers for all eligible partners in this round
    const offerExpiresAt = new Date(Date.now() + OFFER_TIMEOUT * 1000);
    await Promise.all(
      eligiblePartners.map(({ partnerId, distanceKm }) =>
        prisma.workDispatch.create({
          data: {
            bookingId,
            partnerId,
            round: round + 1,
            status: 'PENDING',
            offerExpiresAt,
            distanceKm,
            etaMinutes: Math.ceil((distanceKm / 30) * 60), // Rough ETA estimate
          },
        })
      )
    );

    // Update booking status
    await prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'PARTNER_OFFERED' },
    });
    await recordStatusChange(bookingId, 'DISPATCHING', 'PARTNER_OFFERED', 'system');

    // Emit to all eligible partners
    for (const { partnerId, distanceKm, partner } of eligiblePartners) {
      const offer = {
        bookingId,
        packageName: booking.package.name,
        clientArea: booking.address,
        distanceKm: Math.round(distanceKm * 10) / 10,
        etaMinutes: Math.ceil((distanceKm / 30) * 60),
        earning: PARTNER_EARNING,
        expiresIn: OFFER_TIMEOUT,
        expiresAt: offerExpiresAt.toISOString(),
        bookingDate: booking.bookingDate,
        timeSlot: booking.timeSlot,
      };

      emitToPartner(partnerId, SOCKET_EVENTS.DISPATCH_NEW, offer);

      if (partner.fcmToken) {
        await sendBookingNotification(partner.fcmToken, {
          title: '🎬 New Booking Request!',
          body: `${booking.package.name} — ₹${PARTNER_EARNING} — ${Math.round(distanceKm * 10) / 10}km away`,
          data: { type: 'NEW_BOOKING_REQUEST', bookingId },
        });
      }
    }

    // Wait for any partner to accept (poll DB for OFFER_TIMEOUT seconds)
    const accepted = await waitForAcceptance(bookingId, offerExpiresAt);

    if (accepted) {
      partnerFound = true;
      break;
    }

    // Expire pending dispatches for this round
    await prisma.workDispatch.updateMany({
      where: { bookingId, status: 'PENDING', round: round + 1 },
      data: { status: 'EXPIRED' },
    });

    // Notify partners offer expired
    for (const { partnerId } of eligiblePartners) {
      emitToPartner(partnerId, SOCKET_EVENTS.DISPATCH_EXPIRED, { bookingId });
    }
  }

  if (!partnerFound) {
    await prisma.booking.update({
      where: { id: bookingId },
      data: { status: 'NO_PARTNER_AVAILABLE' },
    });
    await recordStatusChange(bookingId, 'PARTNER_OFFERED', 'NO_PARTNER_AVAILABLE', 'system');
    emitToClient(booking.userId, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, {
      bookingId,
      status: 'NO_PARTNER_AVAILABLE',
    });
    logger.warn({ bookingId }, 'No partner found after all dispatch rounds');
  }

  return partnerFound;
}

// ── Atomic Partner Acceptance ─────────────────────────────────────────────────
export async function acceptBooking(bookingId: string, partnerId: string): Promise<{
  success: boolean;
  message: string;
}> {
  const lockKey = REDIS_KEYS.bookingDispatchLock(bookingId);

  // Atomic Redis lock (NX = only if not exists)
  const locked = await redis.set(lockKey, partnerId, 'EX', 30, 'NX');
  if (!locked) {
    return { success: false, message: 'Booking already being assigned to another partner' };
  }

  try {
    const result = await prisma.$transaction(async (tx) => {
      // Verify booking is still dispatchable
      const booking = await tx.booking.findUnique({
        where: { id: bookingId },
        select: { status: true, userId: true },
      });
      if (!booking || !['DISPATCHING', 'PARTNER_OFFERED'].includes(booking.status)) {
        return { success: false, message: 'Booking no longer available' };
      }

      // Verify this partner has a PENDING dispatch offer
      const dispatch = await tx.workDispatch.findFirst({
        where: { bookingId, partnerId, status: 'PENDING' },
      });
      if (!dispatch) {
        return { success: false, message: 'No active offer found for this partner' };
      }

      // Check offer not expired
      if (new Date() > dispatch.offerExpiresAt) {
        return { success: false, message: 'Offer has expired' };
      }

      // Verify partner is still active & available
      const partner = await tx.partner.findUnique({
        where: { id: partnerId },
        select: { status: true, verificationStatus: true, isOnline: true, isAvailable: true, canAcceptBookings: true, userId: true },
      });
      if (
        !partner ||
        partner.status !== 'ACTIVE' ||
        !partner.canAcceptBookings ||
        !partner.isOnline ||
        !partner.isAvailable
      ) {
        return { success: false, message: 'Partner not eligible to accept bookings' };
      }

      // Accept: mark this dispatch as accepted
      await tx.workDispatch.update({
        where: { id: dispatch.id },
        data: { status: 'ACCEPTED', respondedAt: new Date() },
      });

      // Cancel all other pending dispatches for this booking
      await tx.workDispatch.updateMany({
        where: { bookingId, id: { not: dispatch.id }, status: 'PENDING' },
        data: { status: 'CANCELLED' },
      });

      // Assign partner to booking
      await tx.booking.update({
        where: { id: bookingId },
        data: {
          partnerId,
          status: 'PARTNER_ASSIGNED',
          partnerAssignedAt: new Date(),
        },
      });

      // Mark partner as busy/unavailable
      await tx.partner.update({
        where: { id: partnerId },
        data: { isAvailable: false },
      });

      return { success: true, clientId: booking.userId };
    });

    if (!result.success) return result;

    // Mark partner busy in Redis
    await setPartnerBusy(partnerId, bookingId);

    await recordStatusChange(bookingId, 'PARTNER_OFFERED', 'PARTNER_ASSIGNED', partnerId);

    // Notify client
    emitToClient(result.clientId!, SOCKET_EVENTS.BOOKING_STATUS_UPDATE, {
      bookingId,
      status: 'PARTNER_ASSIGNED',
    });

    // Broadcast to booking room
    emitToBooking(bookingId, SOCKET_EVENTS.DISPATCH_ACCEPTED, { bookingId, partnerId });

    // Notify other partners their offer was cancelled
    const otherDispatches = await prisma.workDispatch.findMany({
      where: { bookingId, status: 'CANCELLED' },
      select: { partnerId: true },
    });
    for (const { partnerId: otherId } of otherDispatches) {
      emitToPartner(otherId, SOCKET_EVENTS.DISPATCH_EXPIRED, { bookingId });
    }

    logger.info({ bookingId, partnerId }, '✅ Partner accepted booking atomically');
    return { success: true, message: 'Booking accepted successfully' };
  } finally {
    // Always release the lock
    await redis.del(lockKey);
  }
}

// ── Poll for acceptance ───────────────────────────────────────────────────────
async function waitForAcceptance(bookingId: string, expiresAt: Date): Promise<boolean> {
  const pollInterval = 1000; // 1 second
  while (new Date() < expiresAt) {
    const booking = await prisma.booking.findUnique({
      where: { id: bookingId },
      select: { status: true },
    });
    if (booking?.status === 'PARTNER_ASSIGNED') return true;
    if (!booking || ['CANCELLED', 'FAILED', 'NO_PARTNER_AVAILABLE'].includes(booking.status || '')) return false;
    await new Promise((r) => setTimeout(r, pollInterval));
  }
  return false;
}

// ── Record Status Change ──────────────────────────────────────────────────────
export async function recordStatusChange(
  bookingId: string,
  fromStatus: BookingStatus | null | string,
  toStatus: BookingStatus | string,
  changedBy: string,
  reason?: string,
) {
  await prisma.bookingStatusHistory.create({
    data: {
      bookingId,
      fromStatus: fromStatus as BookingStatus,
      toStatus: toStatus as BookingStatus,
      changedBy,
      reason,
    },
  });
}
