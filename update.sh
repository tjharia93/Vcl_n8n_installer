#!/usr/bin/env bash
set -e

echo "============================================"
echo "  VCL n8n Updater"
echo "============================================"
echo ""

if [ ! -f /opt/vcl/config/docker-compose.yml ]; then
  echo "No installation found at /opt/vcl/config/docker-compose.yml"
  exit 1
fi

cd /opt/vcl/config

echo "Pulling latest images..."
docker compose pull

echo "Restarting stack..."
docker compose up -d

echo ""
echo "Waiting for n8n to respond..."
sleep 10

N8N_PORT=$(grep N8N_PORT /opt/vcl/config/.env | cut -d= -f2)
N8N_HOST=$(grep N8N_HOST /opt/vcl/config/.env | cut -d= -f2)

if curl -fsS "http://${N8N_HOST}:${N8N_PORT}" >/dev/null 2>&1; then
  echo "n8n is running and reachable."
else
  echo "Warning: n8n did not respond yet. Check: docker compose logs -f"
fi

echo ""
echo "Update complete."
