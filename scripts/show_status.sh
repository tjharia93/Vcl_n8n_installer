#!/usr/bin/env bash
set -e

echo "============================================"
echo "  VCL n8n Status"
echo "============================================"
echo ""

# Container status
echo "Containers:"
if [ -f /opt/vcl/config/docker-compose.yml ]; then
  cd /opt/vcl/config
  docker compose ps
else
  echo "  No docker-compose.yml found."
fi

echo ""

# n8n reachability
if [ -f /opt/vcl/config/.env ]; then
  N8N_HOST=$(grep "^N8N_HOST=" /opt/vcl/config/.env | cut -d= -f2)
  N8N_PORT=$(grep "^N8N_PORT=" /opt/vcl/config/.env | cut -d= -f2)
  URL="http://${N8N_HOST}:${N8N_PORT}"

  echo "n8n URL: $URL"
  if curl -fsS --max-time 3 "$URL" >/dev/null 2>&1; then
    echo "Status: REACHABLE"
  else
    echo "Status: NOT RESPONDING"
  fi
else
  echo "No .env found."
fi

echo ""

# Disk usage
echo "Disk usage:"
du -sh /opt/vcl/runtime/n8n_data 2>/dev/null || echo "  n8n_data: N/A"
du -sh /opt/vcl/runtime/postgres_data 2>/dev/null || echo "  postgres_data: N/A"
du -sh /opt/vcl/runtime/backups 2>/dev/null || echo "  backups: N/A"
du -sh /opt/vcl/runtime/files 2>/dev/null || echo "  files: N/A"

echo ""
