# ORBIT Marketplace — Master Implementation Plan (v3.0)

## 1. Project Overview & Architecture
ORBIT is a hyperlocal, high-speed professional video marketplace delivering edited reels in ~120 minutes.
- **Workflow:** Client Books & Pays → Redis GEO Dispatch → Partner Accepts & Shoots → Cloudflare R2 Upload → Editor Claims & Cuts → Final Reel QC & Delivery → ₹500 Partner Wallet Credit.

### Tech Stack
- **Backend:** Node.js 20, TypeScript 5, Express 4.x, PostgreSQL 15, Prisma 5.x, Redis 7.x (GEO + BullMQ), Socket.IO 4.x, Pino Logger.
- **Client App (Flutter):** Pure Native Material 3, Kinetic Noir Design System (`#131313`, Cyan/Purple `#00C2FF`→`#9D50FF`), Riverpod, Dio + JWT Refresh Interceptor, MapLibre GL, Razorpay SDK, FCM.
- **Partner App (Flutter):** Pure Native Material 3, Luminous Dark Design System (`#050505`, Neon Green `#4BE277`), Riverpod, Dio + JWT Interceptor, MapLibre GL, Real-time GPS Broadcaster, Camera SDK.
- **Media Storage:** Cloudflare R2 S3-compatible storage with presigned PUT URLs.
- **Payments & Payouts:** Razorpay Orders & Webhooks (Client payments), Cashfree Payouts API (Partner wallet bank withdrawals).

---

## 2. Completed Milestones (Ready & in Repository)

### A. Core Backend & Infrastructure
- [x] Monorepo workspace configuration (`package.json`, `backend/package.json`).
- [x] PostgreSQL database schema (`backend/prisma/schema.prisma`) with all models (`User`, `Partner`, `PartnerWallet`, `WalletTransaction`, `Booking`, `MediaAsset`, `WorkDispatch`, `PartnerVerificationCode`, `AuditLog`, `Package`).
- [x] Redis service for Geo-spatial indexing (`GEOADD`, `GEORADIUS`), atomic distributed locking (`SET key value NX PX`), and dispatch tracking.
- [x] Socket.IO real-time server with typed rooms (`booking:<id>`, `partner:<id>`, `client:<id>`, `admin`).
- [x] Full Auth & Verification subsystem with Gmail SMTP OTPs, rate-limiting (`express-rate-limit`), and 2-Tier Partner Training Verification Codes.
- [x] Complete REST APIs for Bookings, Partner verification, Maps/Routing, Media R2 Presigned URLs, Editor job claiming, Partner Wallets (idempotent crediting), and Admin oversight.
- [x] Razorpay & Cashfree HMAC webhook handlers with idempotent transaction logging.
- [x] BullMQ background workers for automated multi-round dispatch escalation (`2km` -> `5km` -> `10km`).
- [x] Database seeder (`backend/src/seed.ts`) creating packages and master accounts.
- [x] Production Docker Compose configuration (`docker-compose.yml`) for Postgres, Redis, API, and Worker.

### B. Client Flutter App (`client-app/`)
- [x] Removed all WebView dependencies in favor of 100% native Flutter widgets.
- [x] Kinetic Noir theme matching Stitch specifications (`lib/core/theme.dart`).
- [x] GoRouter navigation with reactive auth guards (`lib/core/router.dart`, `lib/core/shell.dart`).
- [x] Splash screen with animated glow logos and transitions (`splash_screen.dart`).
- [x] Passwordless email OTP authentication with secure token storage (`login_screen.dart`, `otp_screen.dart`).
- [x] Dynamic Dashboard / Home screen with recent bookings and stats (`home_screen.dart`).
- [x] Package selection screen with feature checklist & popular indicators (`packages_screen.dart`).
- [x] MapLibre-powered Location Picker with GPS auto-detection & reverse geocoding (`location_picker_screen.dart`).
- [x] Booking review & Time-slot selection (`booking_review_screen.dart`).
- [x] Razorpay payment flow screen (`payment_screen.dart`).
- [x] Pulsing Orbit Partner-Finding screen (`finding_partner_screen.dart`).
- [x] Real-time Booking status screen & Timeline history (`booking_status_screen.dart`).
- [x] Live MapLibre Partner GPS tracking screen with OSRM polylines (`live_tracking_screen.dart`).
- [x] Booking history, notifications, and profile screens.

### C. Partner Flutter App (`partner-app/`)
- [x] Luminous Dark theme (`#050505` background, `#4BE277` Neon Green accents) in `lib/core/theme.dart`.
- [x] GoRouter navigation, separate secure token persistence, and onboarding guards (`lib/core/router.dart`).
- [x] Partner Email OTP Login screen (`partner_login_screen.dart`, `partner_otp_screen.dart`).
- [x] Mandatory 2-Tier Verification Code Onboarding screen (`partner_onboarding_screen.dart`).
- [x] Available Work screen with Online/Offline dispatch toggle and ₹500 booking offers (`available_work_screen.dart`).
- [x] Active Job Lifecycle screen (Arrived -> Shoot -> Upload -> Delivery) in `active_job_screen.dart`.
- [x] Earnings & Wallet screen with lifetime totals and transactions (`earnings_screen.dart`).
- [x] Partner Profile and metrics screen (`partner_profile_screen.dart`).

---

## 3. Next Steps for Coding Partner (Remaining Scope)

1. **Database & Backend Verification:**
   - Run `npx prisma migrate dev` or `docker compose up -d` with PostgreSQL and Redis.
   - Run `npm run seed` in `backend/` to populate default packages and master accounts.
2. **Editor Web App & Admin Dashboard:**
   - Connect `editor-web-app` (Next.js) to `/api/editor/jobs` to claim and submit final reel URLs.
   - Connect `dashboard-web-app` to `/api/admin` for live operations, partner code generation, and payout reviews.
3. **End-to-End Golden Loop Testing:**
   - Test Client Booking -> Partner Accept -> Upload -> Editor Deliver -> ₹500 Wallet Credit.
