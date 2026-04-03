#!/usr/bin/env bash
set -e

echo "[10/10] Importing workflows..."

WORKFLOW_DIR="/opt/vcl/apps/vcl-email-automation/workflows"

if [ ! -d "$WORKFLOW_DIR" ]; then
  echo "  No workflow directory found at $WORKFLOW_DIR. Skipping."
  echo "[10/10] Skipped."
  exit 0
fi

WORKFLOW_COUNT=$(find "$WORKFLOW_DIR" -name "*.json" -type f | wc -l)
if [ "$WORKFLOW_COUNT" -eq 0 ]; then
  echo "  No workflow JSON files found. Skipping."
  echo "[10/10] Skipped."
  exit 0
fi

echo "  Found $WORKFLOW_COUNT workflow file(s). Importing..."

# Copy workflows into container and import
docker exec vcl-n8n sh -c "mkdir -p /tmp/workflows"
docker cp "$WORKFLOW_DIR/." vcl-n8n:/tmp/workflows/

docker exec vcl-n8n n8n import:workflow --separate --input=/tmp/workflows || {
  echo "  WARNING: Workflow import failed. You can retry manually:"
  echo "    docker exec vcl-n8n n8n import:workflow --separate --input=/tmp/workflows"
  exit 0
}

# Clean up temp files in container
docker exec vcl-n8n sh -c "rm -rf /tmp/workflows"

echo "  $WORKFLOW_COUNT workflow(s) imported."
echo "[10/10] Import complete."
