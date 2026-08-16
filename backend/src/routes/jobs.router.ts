import { Router } from 'express';
import { logger } from '../lib/logger';
import { dispatchBooking } from '../services/dispatch.service';
import { processCashfreePayout } from '../services/payout.service';
import { sendBookingNotification } from '../services/fcm.service';

// Important: In a real serverless deployment (Vercel), we'd verify the QStash signature here.
// For now, this internal endpoint simply maps HTTP requests back to the worker functions.

const router = Router();

router.post('/:queueName', async (req, res) => {
  const { queueName } = req.params;
  const { jobName, data } = req.body;

  try {
    if (queueName === 'orbit-dispatch') {
      await dispatchBooking(data.bookingId);
    } else if (queueName === 'orbit-payouts') {
      await processCashfreePayout(data);
    } else if (queueName === 'orbit-notifications') {
      await sendBookingNotification(data.token, data.notification);
    } else {
      return res.status(404).json({ error: 'Unknown queue' });
    }

    res.json({ success: true });
  } catch (err: any) {
    logger.error({ err, queueName }, 'Job execution failed from HTTP trigger');
    res.status(500).json({ error: err.message });
  }
});

export default router;
