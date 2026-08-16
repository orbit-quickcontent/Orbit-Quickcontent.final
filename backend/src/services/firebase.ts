import { initializeApp, getApps, getApp } from "firebase/app";
import { getFirestore } from "firebase/firestore";

const firebaseConfig = {
  apiKey: process.env.FIREBASE_API_KEY || "AIzaSyA4QOCd8Ppfs8MVrmge7XDcrEEYok-jw4E",
  authDomain: "orbit-17d89.firebaseapp.com",
  projectId: "orbit-17d89",
  storageBucket: "orbit-17d89.firebasestorage.app",
  messagingSenderId: "105735237809858792956",
  appId: "1:105735237809858792956:web:c31d0312af94549b3f3704"
};

const app = getApps().length === 0 ? initializeApp(firebaseConfig) : getApp();
const db = getFirestore(app);

export { app, db };
