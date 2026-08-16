# ORBIT Platform Deployment Runbook

## Overview
This runbook describes the deployment architecture and standard operating procedures (SOPs) for the ORBIT marketplace.

## Infrastructure Stack
- **Database**: PostgreSQL 15 (Managed or via Docker)
- **Cache / PubSub**: Redis 7.x
- **Backend API**: Node.js 20 (Express + Socket.IO + BullMQ)
- **Frontend / Admin**: Next.js
- **Mobile Apps**: Flutter 3.19.x
- **Monitoring**: Prometheus + Grafana, Sentry

## Deployment Strategy
We use automated CI/CD pipelines via GitHub Actions.
To perform a full manual deployment on a staging server, use the master upgrade script.

### Executing the Upgrade Script
1. SSH into the target server:
   ```bash
   ssh deploy@orbit-staging.example.com
   ```
2. Navigate to the project root:
   ```bash
   cd /var/www/orbit
   ```
3. Run the upgrade script:
   ```bash
   ./scripts/upgrade-all.sh
   ```

### Rolling Back
If a deployment fails:
1. Revert to the previous git commit:
   ```bash
   git checkout <previous-commit-hash>
   ```
2. Re-run the build:
   ```bash
   docker-compose down
   npm install
   npm run build
   docker-compose up -d
   ```

## Monitoring & Troubleshooting
- **Logs**: Check container logs using `docker-compose logs -f orbit-api` or view structured Pino logs.
- **Metrics**: Access Grafana dashboard at `http://<server-ip>:3000` (Default creds configured via environment).
- **Error Tracking**: Visit Sentry dashboard for stack traces and exception reports.

## Database Migrations
Prisma handles database schema migrations. Migrations run automatically during `./scripts/upgrade-all.sh`.
To run manually:
```bash
cd backend
npx prisma migrate deploy
```
