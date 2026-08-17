# ORBIT Engineering — On-Call Rotation & Incident Escalation Policy

## 1. On-Call Schedule
- **Primary On-Call:** Weekly rotation starting Mondays at 09:00 IST.
- **Secondary / Escalation Lead:** Engineering Lead.

## 2. Severity Levels & Response Times
| Severity | Description | Response SLA | Target Resolution |
|---|---|---|---|
| **SEV-1 (Critical)** | Booking outages, payment failure, dispatch engine down | < 15 minutes | < 1 hour |
| **SEV-2 (High)** | Delayed footage uploads, partner location syncing degradation | < 30 minutes | < 4 hours |
| **SEV-3 (Medium)** | Dashboard UI anomalies, non-blocking telemetry issues | < 2 hours | Next business day |

## 3. Escalation Procedure
1. Acknowledge alert on PagerDuty / Telegram Ops bot.
2. Open Incident War Room on Discord/Slack.
3. Check Sentry error feed and Vercel/Docker logs.
4. Execute recovery SOP from `docs/disaster-recovery.md`.
5. Post post-mortem report within 24 hours of SEV-1 resolution.
