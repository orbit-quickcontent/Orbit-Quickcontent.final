import { initializeApp, getApps, getApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";
import { getAuth } from "firebase/auth";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyAJ5I1KYkkl6Y8DysBhQ9CofenqmWBQSb0",
  authDomain: "orbit-17d89.firebaseapp.com",
  projectId: "orbit-17d89",
  storageBucket: "orbit-17d89.firebasestorage.app",
  messagingSenderId: "753333113627",
  appId: "1:753333113627:web:4566e510bc5198f5ecf9be",
  measurementId: "G-M9BQPHK76C"
};

// Initialize Firebase
const app = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
const auth = getAuth(app);
const db = getFirestore(app);

let analytics;
if (typeof window !== "undefined") {
  try {
    analytics = getAnalytics(app);
  } catch (e) {
    // Analytics not supported in all environments
  }
}

export { app, auth, db, analytics };

