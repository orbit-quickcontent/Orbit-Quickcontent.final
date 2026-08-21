import { initializeApp } from "firebase/app";
import { getFirestore, doc, setDoc, collection, writeBatch } from "firebase/firestore";

const firebaseConfig = {
  apiKey: "AIzaSyAJ5I1KYkkl6Y8DysBhQ9CofenqmWBQSb0",
  authDomain: "orbit-17d89.firebaseapp.com",
  projectId: "orbit-17d89",
  storageBucket: "orbit-17d89.firebasestorage.app",
  messagingSenderId: "753333113627",
  appId: "1:753333113627:web:3765324e8395bdd5ecf9be",
  measurementId: "G-8JVPLNWPSY"
};

console.log("🚀 [Firestore Enhancement] Initializing Firebase connection to 'orbit-17d89'...");
const app = initializeApp(firebaseConfig);
const db = getFirestore(app);

// ── 1. PACKAGES ─────────────────────────────────────────────────────────────
const packages = [
  {
    id: "pkg_quick",
    name: "Quick Reel",
    tier: "QUICK",
    price: 99900,
    priceDisplay: 999,
    partnerPayout: 40000,
    partnerPayoutDisplay: 400,
    focus: "1 High-Impact 9:16 Reel",
    deliveryTime: "60 mins delivery",
    features: [
      "1 Edited Short-form Reel (30-60s)",
      "Pro Color Grading & Music Sync",
      "Dynamic Captions & Transitions",
      "60-min Fast-track Delivery",
      "1 Quick Revision"
    ],
    popular: false,
    isActive: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: "pkg_standard",
    name: "Creator Standard",
    tier: "STANDARD",
    price: 199900,
    priceDisplay: 1999,
    partnerPayout: 85000,
    partnerPayoutDisplay: 850,
    focus: "2 Cinematic Reels + Raw Footage",
    deliveryTime: "90 mins delivery",
    features: [
      "2 Edited 4K/1080p Reels",
      "All Raw Footage Transferred",
      "Trending Audio & SFX Mixing",
      "Brand Color Matching",
      "2 Revision Rounds"
    ],
    popular: true,
    isActive: true,
    createdAt: new Date().toISOString(),
  },
  {
    id: "pkg_brand",
    name: "Brand Premium",
    tier: "BRAND",
    price: 399900,
    priceDisplay: 3999,
    partnerPayout: 180000,
    partnerPayoutDisplay: 1800,
    focus: "4 Pro Reels + Full Brand DNA Kit",
    deliveryTime: "120 mins delivery",
    features: [
      "4 Multi-Angle Pro Reels",
      "Full Brand DNA & Logo Integration",
      "4K Master Pro Exports",
      "Dedicated Editor Direct Chat",
      "Priority Same-Day Turnaround",
      "Unlimited Minor Revisions"
    ],
    popular: false,
    isActive: true,
    createdAt: new Date().toISOString(),
  }
];

// ── 2. VERIFIED CREATORS / PARTNERS ─────────────────────────────────────────
const partners = [
  {
    id: "ptr_arjun_01",
    userId: "usr_arjun",
    displayName: "Arjun Mehta",
    email: "arjun.creator@orbit.com",
    phone: "+91 98765 11223",
    rating: 4.96,
    reviewCount: 142,
    completedShoots: 138,
    isOnline: true,
    status: "ACTIVE",
    isVerified: true,
    equipment: ["Sony A7 IV", "DJI RS 3 Mini", "Rode Wireless PRO", "iPhone 15 Pro Max"],
    specialties: ["Nightlife", "Fashion & Lifestyle", "Dining / Cafes", "Automotive"],
    location: {
      address: "Connaught Place, New Delhi",
      latitude: 28.6315,
      longitude: 77.2167,
    },
    wallet: {
      balance: 14250,
      pendingPayout: 2400,
      totalEarned: 168400,
    },
    joinedAt: "2025-11-10T10:00:00.000Z",
    avatarUrl: "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&auto=format&fit=crop&q=80"
  },
  {
    id: "ptr_priya_02",
    userId: "usr_priya",
    displayName: "Priya Sharma",
    email: "priya.creator@orbit.com",
    phone: "+91 98765 44556",
    rating: 4.92,
    reviewCount: 98,
    completedShoots: 95,
    isOnline: true,
    status: "ACTIVE",
    isVerified: true,
    equipment: ["Sony FX3", "DJI Mic 2", "Godox ML60", "iPhone 16 Pro"],
    specialties: ["Beauty & Wellness", "Corporate / Events", "Street Food", "Fitness"],
    location: {
      address: "Hauz Khas Village, New Delhi",
      latitude: 28.5535,
      longitude: 77.1944,
    },
    wallet: {
      balance: 9800,
      pendingPayout: 1800,
      totalEarned: 114500,
    },
    joinedAt: "2026-01-05T10:00:00.000Z",
    avatarUrl: "https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&auto=format&fit=crop&q=80"
  },
  {
    id: "ptr_rohit_03",
    userId: "usr_rohit",
    displayName: "Rohit Verma",
    email: "rohit.creator@orbit.com",
    phone: "+91 98765 77889",
    rating: 4.88,
    reviewCount: 76,
    completedShoots: 72,
    isOnline: true,
    status: "ACTIVE",
    isVerified: true,
    equipment: ["Canon R6 Mark II", "Zhiyun Crane 2S", "DJI Osmo Pocket 3"],
    specialties: ["Tech Reviews", "Real Estate", "Events", "Podcast Clips"],
    location: {
      address: "Cyber City, Gurugram",
      latitude: 28.4952,
      longitude: 77.0891,
    },
    wallet: {
      balance: 6200,
      pendingPayout: 850,
      totalEarned: 89300,
    },
    joinedAt: "2026-02-12T10:00:00.000Z",
    avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&auto=format&fit=crop&q=80"
  }
];

// ── 3. DEMO CLIENT USERS ─────────────────────────────────────────────────────
const users = [
  {
    id: "usr_client_demo",
    email: "client@orbit.com",
    name: "Alex Morgan",
    phone: "+91 98111 22334",
    role: "CLIENT",
    walletBalance: 2500,
    activeBookingsCount: 1,
    totalBookingsCount: 8,
    createdAt: new Date().toISOString(),
  },
  {
    id: "usr_brand_demo",
    email: "brand@orbit.com",
    name: "Urban Socials Studio",
    phone: "+91 98222 33445",
    role: "CLIENT",
    walletBalance: 12000,
    activeBookingsCount: 2,
    totalBookingsCount: 24,
    createdAt: new Date().toISOString(),
  }
];

// ── 4. SAMPLE ACTIVE & COMPLETED BOOKINGS ──────────────────────────────────
const sampleBookings = [
  {
    id: "orb_bk_live_01",
    userId: "usr_client_demo",
    clientName: "Alex Morgan",
    clientPhone: "+91 98111 22334",
    partnerId: "ptr_arjun_01",
    partnerName: "Arjun Mehta",
    partnerPhone: "+91 98765 11223",
    packageId: "pkg_standard",
    packageName: "Creator Standard",
    packagePrice: 1999,
    status: "EN_ROUTE",
    paymentStatus: "PAID",
    paymentId: "pay_live_test_001",
    latitude: 28.6139,
    longitude: 77.2090,
    address: "India Gate, Rajpath, New Delhi",
    scheduledAt: new Date(Date.now() + 30 * 60000).toISOString(),
    timeSlot: "Immediate",
    notes: "Outdoor golden hour reel for personal brand launch.",
    etaMinutes: 8,
    timeline: [
      { status: "PENDING_PAYMENT", timestamp: new Date(Date.now() - 25 * 60000).toISOString() },
      { status: "PAID", timestamp: new Date(Date.now() - 20 * 60000).toISOString() },
      { status: "DISPATCHING", timestamp: new Date(Date.now() - 19 * 60000).toISOString() },
      { status: "PARTNER_ASSIGNED", timestamp: new Date(Date.now() - 15 * 60000).toISOString() },
      { status: "EN_ROUTE", timestamp: new Date(Date.now() - 10 * 60000).toISOString() }
    ],
    deliverables: {
      rawFootageUrl: null,
      previewVideoUrl: null,
      finalVideoUrl: null,
      status: "PENDING_SHOOT"
    },
    createdAt: new Date(Date.now() - 25 * 60000).toISOString(),
    updatedAt: new Date().toISOString()
  },
  {
    id: "orb_bk_comp_02",
    userId: "usr_client_demo",
    clientName: "Alex Morgan",
    clientPhone: "+91 98111 22334",
    partnerId: "ptr_priya_02",
    partnerName: "Priya Sharma",
    partnerPhone: "+91 98765 44556",
    packageId: "pkg_quick",
    packageName: "Quick Reel",
    packagePrice: 999,
    status: "COMPLETED",
    paymentStatus: "PAID",
    paymentId: "pay_prev_comp_002",
    latitude: 28.5355,
    longitude: 77.2610,
    address: "Lotus Temple, Kalkaji, New Delhi",
    scheduledAt: new Date(Date.now() - 48 * 3600000).toISOString(),
    timeSlot: "Evening (5PM-9PM)",
    notes: "Architecture & evening ambient reel.",
    rating: 5,
    review: "Incredible speed and cinematic shots! Delivered the reel in under 50 minutes.",
    deliverables: {
      rawFootageUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      previewVideoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      finalVideoUrl: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4",
      status: "DELIVERED"
    },
    createdAt: new Date(Date.now() - 49 * 3600000).toISOString(),
    updatedAt: new Date(Date.now() - 47 * 3600000).toISOString()
  }
];

// ── 5. SEED EXECUTION ───────────────────────────────────────────────────────
async function seedEnhancedFirestore() {
  try {
    console.log("📦 Seeding Packages...");
    for (const pkg of packages) {
      await setDoc(doc(db, "packages", pkg.id), pkg, { merge: true });
      console.log(`  ✅ Package: ${pkg.name} (₹${pkg.priceDisplay})`);
    }

    console.log("\n👥 Seeding Creator Partners...");
    for (const ptr of partners) {
      await setDoc(doc(db, "partners", ptr.id), ptr, { merge: true });
      console.log(`  ✅ Partner: ${ptr.displayName} (${ptr.rating} ★ - ${ptr.location.address})`);
    }

    console.log("\n👤 Seeding Client Users...");
    for (const u of users) {
      await setDoc(doc(db, "users", u.id), u, { merge: true });
      console.log(`  ✅ User: ${u.name} (${u.email})`);
    }

    console.log("\n🎬 Seeding Sample & Active Bookings...");
    for (const bk of sampleBookings) {
      await setDoc(doc(db, "bookings", bk.id), bk, { merge: true });
      console.log(`  ✅ Booking: ${bk.id} - ${bk.packageName} [${bk.status}]`);
    }

    console.log("\n✨ [Firestore Enhancement Complete] Successfully seeded database collections on 'orbit-17d89'!");
  } catch (error) {
    console.error("❌ Error seeding Firestore:", error);
  }
}

seedEnhancedFirestore();
