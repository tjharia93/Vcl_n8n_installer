#!/usr/bin/env bash
set -e

echo "[7/10] Starting n8n stack..."

cd /opt/vcl/config
docker compose up -d

echo "  Containers started."
docker compose ps
echo "[7/10] Stack started."
