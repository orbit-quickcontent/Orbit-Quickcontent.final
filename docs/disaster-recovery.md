# ORBIT v3.0 - Disaster Recovery Plan

This document outlines the standard operating procedures (SOPs) for handling system outages, data loss, or infrastructure compromise in the ORBIT Marketplace.

## 1. Core Principles
1. **Zero Data Loss:** Booking, wallet, and media metadata take absolute priority over uptime.
2. **Atomic Rollbacks:** All database transactions (Prisma) for financial/status updates are atomic. Roll back code before trying to fix data manually.
3. **Idempotency:** Payment webhooks (Razorpay) and Payouts (Cashfree) are idempotent. Replaying failed webhooks will not result in double credits.

## 2. PostgreSQL Database Recovery
The production PostgreSQL database uses automated WAL archiving and daily snapshots.

### Scenario A: Accidental Data Deletion
1. Identify the timestamp of the deletion.
2. Spin up a Point-in-Time Recovery (PITR) instance from the cloud provider (e.g., Supabase/AWS RDS).
3. Export the missing rows to CSV.
4. Import into the live production database.
**Never** overwrite the entire live database for a small accidental deletion.

### Scenario B: Full Database Corruption
1. Stop all backend and worker services immediately (`docker-compose stop backend worker`).
2. Restore the latest daily snapshot to a new instance.
3. Apply WAL logs up to the failure point.
4. Update `DATABASE_URL` in the `.env` file.
5. Restart services (`docker-compose up -d`).

## 3. Redis Data Loss (Queue & Locations)
Redis is used for ephemeral data (partner locations) and BullMQ queues (dispatching).

### Scenario: Redis Instance Crashes / Data Flushed
1. **Locations:** Partner apps will automatically re-broadcast their locations every 5 seconds. No action needed; state will self-heal within 10 seconds.
2. **Queues (BullMQ):** Active dispatch jobs will be lost.
   - Run the recovery script to re-queue stuck bookings: `npm run script:recover-stuck-bookings`
   - This script finds all bookings in `FINDING_PARTNER` status without active locks and re-adds them to the `dispatchQueue`.

## 4. Media Storage (Cloudflare R2) Outage
If Cloudflare R2 is down, partners cannot upload raw footage and editors cannot upload reels.

### Scenario: R2 Upload Failures
1. The Partner App is designed to cache footage locally on the device.
2. Send an FCM broadcast via the Admin Dashboard informing partners of the delay.
3. Once R2 returns, partners can click "Retry Sync" on their Active Job screen.
4. Booking status will remain in `UPLOAD_PENDING` until successful.

## 5. Payment Gateway (Razorpay/Cashfree) Outage
1. **Razorpay Down:** Clients cannot book. Display maintenance banner.
2. **Cashfree Down:** Partners cannot withdraw wallet balance. Withdrawals will remain in `PENDING` state. BullMQ will retry payout jobs with exponential backoff up to 24 hours.

## 6. Emergency Contact Matrix
| Role | Contact | Primary Responsibility |
|------|---------|------------------------|
| DevOps / SRE | devops@orbit.com | Infrastructure, DB Restores, Docker |
| Backend Lead | backend@orbit.com | Redis, API failures, Webhooks |
| Flutter Lead | mobile@orbit.com | App force updates, cached data |
