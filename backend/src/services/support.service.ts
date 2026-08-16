import prisma from '../lib/prisma';
import { Server } from 'socket.io';
import { logger } from '../lib/logger';

export class SupportService {
  /**
   * Create a new support ticket
   */
  static async createTicket(userId: string, subject: string, description: string) {
    const ticket = await prisma.notification.create({
      data: {
        userId,
        title: `Support Ticket: ${subject}`,
        body: description,
        channel: 'IN_APP',
        data: { type: 'TICKET_CREATED' },
      }
    });
    return ticket;
  }

  /**
   * Initialize Live Chat via Socket.IO
   */
  static initLiveChat(io: Server) {
    io.on('connection', (socket) => {
      socket.on('join_chat', (data) => {
        const { userId, role } = data;
        const room = `chat:${userId}`;
        socket.join(room);
        logger.info(`User ${userId} joined chat room ${room}`);
      });

      socket.on('send_message', (data) => {
        const { userId, message, role } = data;
        const room = `chat:${userId}`;
        // Broadcast to the user's chat room (Admin and User)
        io.to(room).emit('receive_message', {
          senderRole: role,
          message,
          timestamp: new Date().toISOString(),
        });
      });
    });
  }
}
