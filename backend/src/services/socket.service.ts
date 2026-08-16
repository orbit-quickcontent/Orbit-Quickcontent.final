import { createClient, SupabaseClient } from '@supabase/supabase-js';
import { logger } from '../lib/logger';
import { Server as HttpServer } from 'http';

let supabase: SupabaseClient;

export function initSocketService(httpServer?: HttpServer) {
  if (!process.env.SUPABASE_URL || !process.env.SUPABASE_SERVICE_ROLE_KEY) {
    logger.warn('Supabase Realtime not initialized: Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY');
    return null;
  }
  
  supabase = createClient(
    process.env.SUPABASE_URL,
    process.env.SUPABASE_SERVICE_ROLE_KEY,
    {
      auth: { persistSession: false },
    }
  );

  logger.info('✅ Supabase Realtime service initialized (Serverless Socket replacement)');
  return supabase;
}

export function getIO() {
  if (!supabase) {
    initSocketService();
  }
  if (!supabase) throw new Error('Supabase Realtime client not initialized');
  return supabase;
}

// ── Emit Helpers (Mapped to Supabase Channels) ─────────────────────────────

async function broadcastToChannel(channelName: string, event: string, payload: any) {
  try {
    const channel = getIO().channel(channelName);
    await channel.send({
      type: 'broadcast',
      event,
      payload
    });
    logger.debug({ channelName, event }, 'Broadcasted realtime event');
  } catch (err: any) {
    logger.error({ channelName, event, err: err.message }, 'Failed to broadcast realtime event');
  }
}

export function emitToBooking(bookingId: string, event: string, data: any) {
  broadcastToChannel(`booking:${bookingId}`, event, data);
}

export function emitToPartner(partnerId: string, event: string, data: any) {
  broadcastToChannel(`partner:${partnerId}`, event, data);
}

export function emitToClient(clientId: string, event: string, data: any) {
  broadcastToChannel(`client:${clientId}`, event, data);
}

export function emitToEditor(editorId: string, event: string, data: any) {
  broadcastToChannel(`editor:${editorId}`, event, data);
}

export function emitToAdmin(event: string, data: any) {
  broadcastToChannel('admin:ops', event, data);
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
