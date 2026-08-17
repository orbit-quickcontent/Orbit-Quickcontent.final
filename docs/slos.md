# ORBIT Service Level Objectives (SLOs) & Reliability Targets

## 1. Availability SLOs
- **Platform Availability:** 99.9% uptime across all user-facing web and mobile APIs (monthly target).
- **Payment & Escrow Reliability:** 99.99% success rate for verified payment transactions.

## 2. Latency SLOs
- **API Response Latency:**
  - 95th percentile (p95): < 250ms for authenticated REST read requests.
  - 99th percentile (p99): < 600ms for booking dispatch triggers.
- **WebSocket / Realtime Location Sync:**
  - Latency < 1.0 second between partner device update and client HUD render.

## 3. Post-Production Turnaround SLOs
- **Personalized Shoot Delivery:** 90% of deliveries completed within 90 minutes of upload.
- **UGC Pro Shoot Delivery:** 90% of deliveries completed within 120 minutes of upload.
