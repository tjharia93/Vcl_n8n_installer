#!/usr/bin/env bash
set -e

EXPORT_DIR="/opt/vcl/runtime/files/exports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
EXPORT_FILE="$EXPORT_DIR/workflows_$TIMESTAMP.json"

mkdir -p "$EXPORT_DIR"

echo "Exporting workflows from n8n..."

docker exec vcl-n8n n8n export:workflow --all --output=/tmp/export.json
docker cp vcl-n8n:/tmp/export.json "$EXPORT_FILE"
docker exec vcl-n8n rm -f /tmp/export.json

echo "Workflows exported to: $EXPORT_FILE"
