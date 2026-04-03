#!/usr/bin/env bash
set -e

BACKUP_DIR="/opt/vcl/runtime/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$BACKUP_DIR/vcl_backup_$TIMESTAMP.tar.gz"

echo "Creating backup..."

# Ensure backup directory exists
mkdir -p "$BACKUP_DIR"

# Export workflows from running n8n
echo "  Exporting workflows..."
docker exec vcl-n8n n8n export:workflow --all --output=/tmp/workflow_backup.json 2>/dev/null || \
  echo "  Warning: Could not export workflows (n8n may not be running)."

# Create the backup archive
echo "  Archiving data..."
tar -czf "$BACKUP_FILE" \
  -C /opt/vcl \
  config/.env \
  config/docker-compose.yml \
  runtime/n8n_data \
  2>/dev/null || true

# Include postgres data if it exists and has content
if [ -d "/opt/vcl/runtime/postgres_data" ] && [ "$(ls -A /opt/vcl/runtime/postgres_data 2>/dev/null)" ]; then
  echo "  Including PostgreSQL data..."
  tar -rzf "$BACKUP_FILE" -C /opt/vcl runtime/postgres_data 2>/dev/null || true
fi

echo "  Backup saved to: $BACKUP_FILE"
echo "  Size: $(du -h "$BACKUP_FILE" | cut -f1)"
echo "Backup complete."
