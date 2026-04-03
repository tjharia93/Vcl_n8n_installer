#!/usr/bin/env bash
set -e

BACKUP_FILE="$1"

if [ -z "$BACKUP_FILE" ]; then
  echo "Usage: $0 <backup_file.tar.gz>"
  echo ""
  echo "Available backups:"
  ls -lh /opt/vcl/runtime/backups/*.tar.gz 2>/dev/null || echo "  No backups found."
  exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
  echo "ERROR: Backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "Restoring from: $BACKUP_FILE"
read -rp "This will overwrite current data. Continue? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

# Stop the stack
echo "Stopping n8n stack..."
cd /opt/vcl/config
docker compose down

# Extract backup
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C /opt/vcl

# Restart
echo "Starting stack..."
docker compose up -d

echo "Restore complete. Check: docker compose logs -f"
