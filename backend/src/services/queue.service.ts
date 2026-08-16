import { logger } from '../lib/logger';
import { dispatchBooking } from './dispatch.service';
import { processCashfreePayout } from './payout.service';
import { sendBookingNotification } from './fcm.service';

// Serverless-compatible Job Queue Adapter (Replacing BullMQ)
// This interface matches BullMQ's queue.add() to prevent breaking callers.
class ServerlessQueue {
  constructor(public queueName: string) {}

  async add(jobName: string, data: any, options?: any) {
    logger.info({ queueName: this.queueName, jobName }, 'Enqueuing job');

    const qstashToken = process.env.QSTASH_TOKEN;
    if (qstashToken && process.env.NEXT_PUBLIC_API_URL) {
      // Send to Upstash QStash
      const endpoint = `${process.env.NEXT_PUBLIC_API_URL}/api/internal/jobs/${this.queueName}`;
      await fetch(`https://qstash.upstash.io/v2/publish/${endpoint}`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${qstashToken}`,
          'Content-Type': 'application/json',
          'Upstash-Delay': options?.delay ? `${options.delay}ms` : '0s'
        },
        body: JSON.stringify({ jobName, data, options }),
      });
      logger.info('Job published to QStash');
    } else {
      // Local development fallback: execute asynchronously in the background
      logger.info('Executing job inline (No QStash token found)');
      this.executeInline(jobName, data).catch(err => {
        logger.error({ err, queueName: this.queueName }, 'Inline job execution failed');
      });
    }
  }

  private async executeInline(jobName: string, data: any) {
    if (this.queueName === 'orbit-dispatch') {
      await dispatchBooking(data.bookingId);
    } else if (this.queueName === 'orbit-payouts') {
      await processCashfreePayout(data);
    } else if (this.queueName === 'orbit-notifications') {
      await sendBookingNotification(data.token, data.notification);
    }
  }
}

export const dispatchQueue = new ServerlessQueue('orbit-dispatch');
export const payoutQueue = new ServerlessQueue('orbit-payouts');
export const notificationQueue = new ServerlessQueue('orbit-notifications');

export function initWorkers() {
  logger.info('Serverless architecture: BullMQ workers are no longer initialized in a persistent process. Jobs run via HTTP/QStash.');
  return {};
}
