import { logger } from '../lib/logger';
import { firestore } from './firebase-admin';

export function initSocketService() {
  logger.info('✅ Firebase Realtime/Firestore event service initialized');
  return true;
}

// ── Emit Helpers (Mapped to Firestore Realtime Collections) ───────────────────

async function broadcastToFirestore(channelName: string, event: string, payload: any) {
  try {
    const eventDoc = {
      channel: channelName,
      event,
      payload,
      createdAt: new Date().toISOString(),
    };
    await firestore.collection('realtime_events').add(eventDoc);
    logger.debug({ channelName, event }, 'Broadcasted Firestore realtime event');
  } catch (err: any) {
    logger.error({ channelName, event, err: err.message }, 'Failed to record realtime event in Firestore');
  }
}

export function emitToBooking(bookingId: string, event: string, data: any) {
  broadcastToFirestore(`booking:${bookingId}`, event, data);
}

export function emitToPartner(partnerId: string, event: string, data: any) {
  broadcastToFirestore(`partner:${partnerId}`, event, data);
}

export function emitToClient(clientId: string, event: string, data: any) {
  broadcastToFirestore(`client:${clientId}`, event, data);
}

export function emitToEditor(editorId: string, event: string, data: any) {
  broadcastToFirestore(`editor:${editorId}`, event, data);
}

export function emitToAdmin(event: string, data: any) {
  broadcastToFirestore('admin:ops', event, data);
}

// ── Typed Event Names ─────────────────────────────────────────────────────────
export const SOCKET_EVENTS = {
  DISPATCH_NEW: 'dispatch:new',
  DISPATCH_EXPIRED: 'dispatch:expired',
  DISPATCH_ACCEPTED: 'dispatch:accepted',
  BOOKING_STATUS_UPDATE: 'booking:status-update',
  PARTNER_LOCATION: 'partner:location',
  PARTNER_ARRIVED: 'partner:arrived',
  SHOOTING_STARTED: 'shooting:started',
  SHOOTING_COMPLETED: 'shooting:completed',
  UPLOAD_PROGRESS: 'upload:progress',
  UPLOAD_COMPLETED: 'upload:completed',
  EDITOR_JOB_AVAILABLE: 'editor:job-available',
  EDITOR_JOB_CLAIMED: 'editor:job-claimed',
  EDITING_STARTED: 'editing:started',
  EDITING_COMPLETED: 'editing:completed',
  BOOKING_DELIVERED: 'booking:delivered',
  WALLET_CREDITED: 'wallet:credited',
  PAYOUT_REQUESTED: 'payout:requested',
  PAYOUT_COMPLETED: 'payout:completed',
  PAYOUT_FAILED: 'payout:failed',
} as const;
