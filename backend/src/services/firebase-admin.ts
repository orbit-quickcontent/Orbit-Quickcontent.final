import * as admin from 'firebase-admin';
import { logger } from '../lib/logger';

const projectId = process.env.FIREBASE_PROJECT_ID || 'orbit-17d89';
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL || '';
const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY || '';
const privateKey = rawPrivateKey ? rawPrivateKey.replace(/\\n/g, '\n') : '';
const storageBucket = process.env.FIREBASE_STORAGE_BUCKET || `${projectId}.firebasestorage.app`;

if (!admin.apps.length) {
  try {
    if (clientEmail && privateKey) {
      admin.initializeApp({
        credential: admin.credential.cert({
          projectId,
          clientEmail,
          privateKey,
        }),
        storageBucket,
      });
      logger.info({ projectId, storageBucket }, '✅ Firebase Admin initialized successfully');
    } else {
      admin.initializeApp({ projectId });
      logger.info({ projectId }, 'ℹ️ Firebase Admin initialized with project ID');
    }
  } catch (err: any) {
    logger.warn({ err: err.message }, '⚠️ Firebase Admin fallback initialization');
    try {
      admin.initializeApp({ projectId });
    } catch (_) {}
  }
}

export const firebaseAdmin = admin;

// Resilient proxies/accessors that don't crash on import
function getSafeFirestore(): admin.firestore.Firestore {
  try {
    return admin.firestore();
  } catch (e) {
    logger.warn('Firestore service requested before initialization');
    return {} as any;
  }
}

function getSafeStorage(): admin.storage.Storage {
  try {
    return admin.storage();
  } catch (e) {
    return {} as any;
  }
}

function getSafeAuth(): admin.auth.Auth {
  try {
    return admin.auth();
  } catch (e) {
    return {} as any;
  }
}

export const firestore = getSafeFirestore();
export const firebaseStorage = getSafeStorage();
export const firebaseAuth = getSafeAuth();

export default admin;
