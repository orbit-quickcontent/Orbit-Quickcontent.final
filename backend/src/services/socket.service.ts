import { Server as SocketServer } from 'socket.io';
import { Server as HttpServer } from 'http';
import jwt from 'jsonwebtoken';
import { logger } from '../lib/logger';

let io: SocketServer;

export function initSocketService(httpServer: HttpServer) {
  io = new SocketServer(httpServer, {
    cors: {
      origin: (process.env.ALLOWED_ORIGINS || 'http://localhost:3000').split(','),
      credentials: true,
    },
    pingTimeout: 20000,
    pingInterval: 25000,
    transports: ['websocket', 'polling'],
  });

  // ── Auth Middleware ─────────────────────────────────────────────────────────
  io.use((socket, next) => {
    const token = socket.handshake.auth?.token || socket.handshake.headers?.authorization?.replace('Bearer ', '');
    if (!token) return next(new Error('Authentication required'));

    try {
      const payload = jwt.verify(token, process.env.JWT_SECRET!) as any;
      socket.data.user = payload;
      next();
    } catch {
      next(new Error('Invalid token'));
    }
  });

  // ── Connection Handler ──────────────────────────────────────────────────────
  io.on('connection', (socket) => {
    const user = socket.data.user;
    logger.info({ userId: user.id, role: user.role }, 'Socket connected');

    // Join personal room
    socket.join(`user:${user.id}`);
    if (user.role === 'PARTNER') socket.join(`partner:${user.id}`);
    if (user.role === 'CLIENT') socket.join(`client:${user.id}`);
    if (user.role === 'EDITOR') socket.join(`editor:${user.id}`);
    if (user.role === 'ADMIN' || user.role === 'SUPER_ADMIN') socket.join('admin:ops');

    // Join booking room
    socket.on('join:booking', (bookingId: string) => {
      socket.join(`booking:${bookingId}`);
      logger.debug({ userId: user.id, bookingId }, 'Joined booking room');
    });

    socket.on('leave:booking', (bookingId: string) => {
      socket.leave(`booking:${bookingId}`);
    });

    socket.on('disconnect', (reason) => {
      logger.info({ userId: user.id, reason }, 'Socket disconnected');
    });

    socket.on('error', (err) => {
      logger.error({ userId: user.id, err: err.message }, 'Socket error');
    });
  });

  logger.info('✅ Socket.IO initialized');
  return io;
}

export function getIO(): SocketServer {
  if (!io) throw new Error('Socket.IO not initialized');
  return io;
}

// ── Emit Helpers ─────────────────────────────────────────────────────────────

export function emitToBooking(bookingId: string, event: string, data: any) {
  getIO().to(`booking:${bookingId}`).emit(event, data);
}

export function emitToPartner(partnerId: string, event: string, data: any) {
  getIO().to(`partner:${partnerId}`).emit(event, data);
}

export function emitToClient(clientId: string, event: string, data: any) {
  getIO().to(`client:${clientId}`).emit(event, data);
}

export function emitToEditor(editorId: string, event: string, data: any) {
  getIO().to(`editor:${editorId}`).emit(event, data);
}

export function emitToAdmin(event: string, data: any) {
  getIO().to('admin:ops').emit(event, data);
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
