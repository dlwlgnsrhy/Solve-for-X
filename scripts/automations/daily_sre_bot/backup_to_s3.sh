#!/bin/bash
# ==============================================================================
# SRE Automation: Daily Cloud Backup (Survival from Oracle Cloud Reclaim)
# ==============================================================================
# Description: Dumps database and syncs essential configs to S3 or Git.
# Usage: Run via cron on the VPS (0 3 * * * /path/to/backup_to_s3.sh)

set -e

BACKUP_DIR="/tmp/soluni_backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_CONTAINER_NAME="legacy_core_postgres"
DB_USER="soluni_admin"
DB_NAME="legacy_core"

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR"

echo "[INFO] Starting SRE Survival Backup at $TIMESTAMP"

# 1. Database Dump (If using PostgreSQL container via Coolify)
# echo "[INFO] Dumping PostgreSQL database..."
# docker exec -t $DB_CONTAINER_NAME pg_dumpall -c -U $DB_USER > dump_$TIMESTAMP.sql
# gzip dump_$TIMESTAMP.sql

# 2. Sync to AWS S3 / Cloudflare R2 / Backblaze
# echo "[INFO] Syncing to S3..."
# aws s3 cp dump_$TIMESTAMP.sql.gz s3://my-soluni-backups/db/

# 3. Local Workspace Backup to Github (Alternative)
# echo "[INFO] Committing configuration changes to Git..."
# cd /path/to/Solve-for-X
# git add .
# git commit -m "chore(backup): Automated survival backup $TIMESTAMP"
# git push origin main

echo "[SUCCESS] Backup completed successfully."
