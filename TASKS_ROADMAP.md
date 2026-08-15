# ORBIT Marketplace — Tasks & Execution Roadmap

This roadmap outlines all completed items and pending tasks for your coding partner.

## 🚀 Phase 1: Core Backend & Database [COMPLETE]
- [x] Monorepo setup with yarn/npm workspaces (`package.json`)
- [x] Full PostgreSQL Prisma schema with 10+ models and indexes (`backend/prisma/schema.prisma`)
- [x] Structured logger (Pino) and Prisma client singleton (`backend/src/lib/`)
- [x] Redis service for Geo-spatial indexing, atomic locking, and caching (`backend/src/services/redis.service.ts`)
- [x] Socket.IO real-time server with typed rooms and event constants (`backend/src/services/socket.service.ts`)
- [x] OTP service with Gmail SMTP transport and DEV-fallback (`backend/src/services/otp.service.ts`)
- [x] Verification code service with bcrypt-hashed codes and audit logging (`backend/src/services/verification.service.ts`)
- [x] Dispatch escalation engine with BullMQ queue integration (`backend/src/services/dispatch.service.ts`)
- [x] Idempotent Partner Wallet & Withdrawal service with Cashfree integration (`backend/src/services/wallet.service.ts`)
- [x] Cloudflare R2 media upload presigned URL generator (`backend/src/api/media/media.routes.ts`)
- [x] Maps service with OSRM routing and fallback calculations (`backend/src/services/maps.service.ts`)
- [x] Express Auth & RBAC middleware with distinct rate limits (`backend/src/middleware/auth.middleware.ts`)
- [x] All REST API route modules (`auth`, `partners`, `bookings`, `wallet`, `maps`, `media`, `editor`, `admin`)
- [x] Razorpay & Cashfree webhook handlers with signature validation (`backend/src/routes/webhook.router.ts`)
- [x] Database seeder (`backend/src/seed.ts`)
- [x] Standalone worker process (`backend/src/worker.ts`)
- [x] Dockerfile & Docker Compose (`docker-compose.yml`)

## 📱 Phase 2: Client Flutter App (Native Kinetic Noir) [COMPLETE]
- [x] Removed `flutter_inappwebview` completely; installed native dependencies
- [x] Full Kinetic Noir design tokens & Typography in `client-app/lib/core/theme.dart`
- [x] GoRouter configuration with Auth guards in `client-app/lib/core/router.dart`
- [x] Splash Screen with animated glowing logo (`splash_screen.dart`)
- [x] Login & OTP verification screens (`login_screen.dart`, `otp_screen.dart`)
- [x] Home / Dashboard screen with dynamic stats & recent bookings (`home_screen.dart`)
- [x] Package Selection screen with feature lists & badges (`packages_screen.dart`)
- [x] MapLibre Location Picker with GPS detection (`location_picker_screen.dart`)
- [x] Booking Review & Time-slot selection (`booking_review_screen.dart`)
- [x] Razorpay Payment screen with checkout integration (`payment_screen.dart`)
- [x] Finding Partner radar screen with Socket.IO room sync (`finding_partner_screen.dart`)
- [x] Booking Status screen with step-by-step progress (`booking_status_screen.dart`)
- [x] Live Partner GPS tracking on MapLibre map (`live_tracking_screen.dart`)
- [x] Booking History, Notifications, and Profile screens

## 🎥 Phase 3: Partner Flutter App (Native Luminous Dark) [COMPLETE]
- [x] Luminous Dark theme system (`#050505`, Neon Green `#4BE277`) in `partner-app/lib/core/theme.dart`
- [x] GoRouter navigation with partner onboarding verification checks
- [x] Partner Email Login & OTP screens (`partner_login_screen.dart`, `partner_otp_screen.dart`)
- [x] Mandatory 2-Tier Training Verification Code screen (`partner_onboarding_screen.dart`)
- [x] Available Work screen with Online/Offline dispatch switch (`available_work_screen.dart`)
- [x] Active Job Lifecycle screen (Arrived -> Shoot -> Upload -> Delivery) in `active_job_screen.dart`
- [x] Wallet & Earnings screen showing ₹500 credits per completed booking (`earnings_screen.dart`)
- [x] Partner Profile and metrics screen (`partner_profile_screen.dart`)

## 💻 Phase 4: Remaining Scope for Handover [READY FOR PARTNER]
- [ ] **Run Database Migrations & Seed:**
  ```bash
  cd backend
  npm install
  npx prisma db push
  npm run seed
  npm run dev
  ```
- [ ] **Run Flutter Client App:**
  ```bash
  cd client-app
  flutter pub get
  flutter run
  ```
- [ ] **Run Flutter Partner App:**
  ```bash
  cd partner-app
  flutter pub get
  flutter run
  ```
- [x] **Phase 5: Admin Dashboard (Next.js)**
  - [x] Replace Firebase with PostgreSQL/Prisma API calls
  - [x] Add Partner Codes management page (`/admin/partner-codes`)
  - [x] Add proper booking state machine display
  - [x] Add dispatch monitoring
  - [x] Add wallet/withdrawal management
- [x] **Phase 6: Editor Web App (Next.js)**
  - [x] Job pool view (EDITOR_AVAILABLE bookings)
  - [x] Atomic job claim via API
  - [x] Footage download + final reel upload
  - [x] QC and delivery flow
- [ ] **End-to-End Golden Loop Testing:**
  - Complete a test booking from Client app -> Accept on Partner app -> Finalize in Editor -> Validate ₹500 wallet credit.
