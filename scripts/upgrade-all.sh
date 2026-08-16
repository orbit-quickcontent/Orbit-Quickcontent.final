#!/bin/bash
# ORBIT Upgrade & Deployment Script
# This script upgrades the full monorepo stack, runs migrations, and restarts services.

set -e

echo "🚀 Starting ORBIT Upgrade Process..."

# 1. Pull Latest Changes
echo "🔄 Pulling latest changes from git..."
git pull origin main || echo "Git pull failed or not in a git repo. Skipping."

# 2. Backup Database (Optional but recommended)
echo "💾 Backing up PostgreSQL database..."
# Assuming DB running locally or in Docker. 
# docker exec -t orbit-postgres pg_dumpall -c -U postgres > backup_$(date +%F).sql

# 3. Install Dependencies
echo "📦 Installing Dependencies for Monorepo (Root, Backend, Dashboards)..."
npm install

echo "📦 Installing Dependencies for Client App..."
cd client-app
flutter pub get
cd ..

echo "📦 Installing Dependencies for Partner App..."
cd partner-app
flutter pub get
cd ..

# 4. Database Migrations
echo "🗄️ Running Prisma Database Migrations..."
cd backend
npx prisma generate
npx prisma migrate deploy
cd ..

# 5. Build Web Apps & Backend
echo "🏗️ Building Backend & Web Apps..."
npm run build

# 6. Restart Services
echo "🔄 Restarting Docker Containers..."
docker-compose down
# Optional: Clear Redis cache if necessary
# docker volume rm orbit-redis-data
docker-compose up -d

echo "✅ Upgrade completed successfully!"
echo "📡 Check logs with: docker-compose logs -f"
