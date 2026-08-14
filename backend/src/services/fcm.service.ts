import admin from 'firebase-admin';
import { logger } from '../lib/logger';

let initialized = false;

function getFirebaseApp() {
  if (initialized) return admin;

  const serviceAccountJson = process.env.FCM_SERVICE_ACCOUNT_JSON;
  if (!serviceAccountJson) {
    logger.warn('FCM_SERVICE_ACCOUNT_JSON not set — push notifications disabled');
    return null;
  }

  try {
    const serviceAccount = JSON.parse(serviceAccountJson);
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    initialized = true;
    logger.info('✅ Firebase Admin initialized');
    return admin;
  } catch (err) {
    logger.error({ err }, 'Failed to initialize Firebase Admin');
    return null;
  }
}

interface NotificationPayload {
  title: string;
  body: string;
  data?: Record<string, string>;
}

export async function sendBookingNotification(
  fcmToken: string,
  notification: NotificationPayload
): Promise<boolean> {
  const app = getFirebaseApp();
  if (!app) return false;

  try {
    await app.messaging().send({
      token: fcmToken,
      notification: { title: notification.title, body: notification.body },
      data: notification.data || {},
      android: {
        priority: 'high',
        notification: {
          channelId: 'orbit_bookings',
          priority: 'high',
          defaultSound: true,
        },
      },
      apns: {
        payload: { aps: { sound: 'default', badge: 1 } },
      },
    });
    return true;
  } catch (err: any) {
    logger.error({ fcmToken: fcmToken.slice(0, 10) + '...', err: err.message }, 'FCM send failed');
    return false;
  }
}

export async function sendMulticastNotification(
  tokens: string[],
  notification: NotificationPayload
): Promise<void> {
  const app = getFirebaseApp();
  if (!app || tokens.length === 0) return;

  const chunks = [];
  for (let i = 0; i < tokens.length; i += 500) {
    chunks.push(tokens.slice(i, i + 500));
  }

  for (const chunk of chunks) {
    try {
      await app.messaging().sendEachForMulticast({
        tokens: chunk,
        notification: { title: notification.title, body: notification.body },
        data: notification.data || {},
      });
    } catch (err: any) {
      logger.error({ err: err.message }, 'FCM multicast failed');
    }
  }
}
