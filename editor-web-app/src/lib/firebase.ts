import { initializeApp } from "firebase/app";
import { getAnalytics } from "firebase/analytics";

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
const app = initializeApp(firebaseConfig);

let analytics;
if (typeof window !== "undefined") {
  analytics = getAnalytics(app);
}

export { app, analytics };
