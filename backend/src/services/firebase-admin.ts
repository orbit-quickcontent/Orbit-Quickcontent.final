import * as admin from 'firebase-admin';
import { logger } from '../lib/logger';

const projectId = process.env.FIREBASE_PROJECT_ID || 'orbit-17d89';
const clientEmail = process.env.FIREBASE_CLIENT_EMAIL || 'firebase-adminsdk-fbsvc@orbit-17d89.iam.gserviceaccount.com';
const rawPrivateKey = process.env.FIREBASE_PRIVATE_KEY || `-----BEGIN PRIVATE KEY-----
MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDOkqbPKkrwLQcS
ijfjUybaTrUhk9TTMFwF2SH8h/SwSGICyshRg/ujunecuW8DXgLfykNW/oxsdo3Z
M3uS96aUZczTsBRzwDH+LeckUaMevgXor65glYCfBobG6PZLER6tDLFmiFtcKOFD
ObJpmYjXChoWc9ff53riwOq+t+cojW8wXyGuHx7NQm1zr8fJEtDGYz3UxEjh4CFK
7RtE9p8QFSi6YtXMAh2cATCLGAa32pwLl33wJierlqj+m765mQjcy3+0+eC3CNVN
OA2u1xjzfObT2G3GwwhQlZgmasj5ZZ/L7tflvNBoosxN501uSBGAxTzLphVZnVeh
1J7iwmJNAgMBAAECggEAAK1dgFSp6e3BdgemEifc+uTvqWErI5iz8IcrJwE8f0U/
4Jtdrg2IXWhlPH1yIvkKE6w9oMZVKDgSR0aoyABP8QqAmHND4EyrJuNriTex5aen
Us411hZSlXlHjbuu4dIEspOiudlgFuY0zz9ChoYzLktK7xoCa7cK6ApMXenLh1s/
1Z5l4pGBazkuWm2+UGLJeBylaZchOEs4psH48lxXrByuSw/3P1GwLZAu7xUdoDMD
92fNKlcd7omnaPkluCsYAlQKxmGSnHIO5w9xPYJ1Ugb+8fGYmGpoUGKJ8MFBdsXm
DPH/qhMJ6aIV7ToxVnd4BZebfBH6ig+v713nSe1bEQKBgQDvQOKMfTTjBQlNiuhH
sDZMICKYPKlxv+azxLMGcvTH8pzqZcFmfTfCzqvglVCXcpWn5kI9JdAuE27P5dun
5Dl/ZyAOs0YXEXXzOZvkLqSAnzdAD4/Ip+nx5UxQt6mTX82PffcUvSB3Hbs7RZcL
gTeYANHN11YpS1Ll5IO1fwGnsQKBgQDdCCwXKtlyvJsYoRzh08BkXD2FFN4AJxu/
4k28fRBlrRrSRFsA/XxfY0YQbsd8AIdNmsvnjgGHYXtB+noJOzuy5geK9Ezoi5NN
aUl4I61YqLtoSI3ThD5kS2jTBxilJwNzr2+PHvSoFg/ymm5x37YcXl/j3rrKd3ie
1YSOzASnXQKBgE+VncZtv7HkcvvAQRPXobgg2GEbjKGx2+Pggkya4KHCKkAuKO8W
p/29EZ9bC7vU+cMn7NC6S02IWUv+gdqPKDEg9KDvMVlrDXkiqKB2g3HlhFNi2ck9
UayNQZ13+ohzTcV1eUMExk/ZK/bDZ0MEcKG3ZBK8loSV8bVXFhjBbqOBAoGAK1W7
1zr2cRFbUyPbVsc+VC7lfN8Pe3YvcZp75TWb7mNW+9yc/v+zz7vV88jUYZJ09Jkh
2x8zW4iYMuJZ5M9xL+z7k5m8LmeXFLlMxzovdU93lsWK0Op/lQhX3+/nPBH/EkJW
G/hUvVO+ArGWb8sNmFhEcperhaCQzItONvT3AJ0CgYBPvZ/uZLVC20L8a+PVrY1O
hWORv/rK1y/zyJtf4jcBR46HI2w6+e4B/bxlMEcm4AjED3lOFhG2qrs006YSjxQF
c0+1p3be+azM1cCzbH8XxFOD6p78LvQSq8KIdRjtwXNJip2VWfQ3pwZp5ZYXqxJV
BdZmy+JjcJsuNx4a5ta55w==
-----END PRIVATE KEY-----`;

const privateKey = rawPrivateKey.replace(/\\n/g, '\n');
const storageBucket = process.env.FIREBASE_STORAGE_BUCKET || `${projectId}.firebasestorage.app`;

if (!admin.apps.length) {
  try {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId,
        clientEmail,
        privateKey,
      }),
      storageBucket,
    });
    logger.info({ projectId, storageBucket }, '✅ Firebase Admin initialized successfully');
  } catch (err: any) {
    logger.error({ err: err.message }, '❌ Failed to initialize Firebase Admin, attempting fallback initialization');
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
