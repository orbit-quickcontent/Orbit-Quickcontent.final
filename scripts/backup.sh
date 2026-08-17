#!/bin/bash
# ==============================================================================
# ORBIT Database Automated Backup Script
# Retention: 30 days
# Destination: Cloudflare R2 / S3 Storage
# ==============================================================================

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/tmp/backups"
BACKUP_FILE="${BACKUP_DIR}/orbit_${TIMESTAMP}.sql.gz"

mkdir -p ${BACKUP_DIR}

echo "[$(date)] Starting ORBIT PostgreSQL backup..."

# Perform pg_dump compressed with gzip
if [ -n "${DATABASE_URL}" ]; then
  pg_dump "${DATABASE_URL}" | gzip > "${BACKUP_FILE}"
else
  pg_dump -h "${DB_HOST:-localhost}" -U "${DB_USER:-orbit_user}" -d "${DB_NAME:-orbit_db}" | gzip > "${BACKUP_FILE}"
fi

echo "[$(date)] Database dumped to ${BACKUP_FILE} ($(du -h ${BACKUP_FILE} | cut -f1))"

# Upload to S3 / Cloudflare R2 if configured
if [ -n "${R2_ENDPOINT}" ] && [ -n "${S3_BUCKET:-orbit-backups}" ]; then
  echo "[$(date)] Uploading backup to R2/S3..."
  aws s3 cp "${BACKUP_FILE}" "s3://${S3_BUCKET:-orbit-backups}/orbit_${TIMESTAMP}.sql.gz" --endpoint-url "${R2_ENDPOINT}"
  echo "[$(date)] Upload completed successfully."
fi

# Clean up local backups older than 30 days
find ${BACKUP_DIR} -name "orbit_*.sql.gz" -mtime +30 -delete
echo "[$(date)] Local backup cleanup completed."
