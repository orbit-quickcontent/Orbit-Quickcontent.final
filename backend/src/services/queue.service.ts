import { Queue, Worker, QueueEvents } from 'bullmq';
import { redisForBull } from './redis.service';
import { logger } from '../lib/logger';

const queueOptions = {
  connection: redisForBull,
  defaultJobOptions: {
    attempts: 3,
    backoff: { type: 'exponential', delay: 5000 },
    removeOnComplete: 100,
    removeOnFail: 200,
  },
};

// ── Queues ────────────────────────────────────────────────────────────────────
export const dispatchQueue = new Queue('orbit-dispatch', queueOptions);
export const payoutQueue = new Queue('orbit-payouts', queueOptions);
export const notificationQueue = new Queue('orbit-notifications', queueOptions);

// ── Workers ────────────────────────────────────────────────────────────────────
export function initWorkers() {
  // Dispatch Worker
  const dispatchWorker = new Worker('orbit-dispatch', async (job) => {
    logger.info({ jobId: job.id, jobName: job.name }, 'Processing dispatch job');
    const { dispatchBooking } = await import('./dispatch.service');
    await dispatchBooking(job.data.bookingId);
  }, { connection: redisForBull, concurrency: 5 });

  dispatchWorker.on('completed', (job) => {
    logger.info({ jobId: job.id }, 'Dispatch job completed');
  });
  dispatchWorker.on('failed', (job, err) => {
    logger.error({ jobId: job?.id, err: err.message }, 'Dispatch job failed');
  });

  // Payout Worker
  const payoutWorker = new Worker('orbit-payouts', async (job) => {
    logger.info({ jobId: job.id }, 'Processing payout job');
    const { processCashfreePayout } = await import('./payout.service');
    await processCashfreePayout(job.data);
  }, { connection: redisForBull, concurrency: 2 });

  payoutWorker.on('failed', (job, err) => {
    logger.error({ jobId: job?.id, err: err.message }, 'Payout job failed');
  });

  // Notification Worker
  const notifWorker = new Worker('orbit-notifications', async (job) => {
    const { sendBookingNotification } = await import('./fcm.service');
    await sendBookingNotification(job.data.token, job.data.notification);
  }, { connection: redisForBull, concurrency: 10 });

  notifWorker.on('failed', (job, err) => {
    logger.error({ jobId: job?.id, err: err.message }, 'Notification job failed');
  });

  logger.info('✅ BullMQ workers initialized (dispatch, payouts, notifications)');

  return { dispatchWorker, payoutWorker, notifWorker };
}
