#!/usr/bin/env bash
set -e

echo "============================================"
echo "  VCL n8n Uninstaller"
echo "============================================"
echo ""

if [ ! -f /opt/vcl/config/docker-compose.yml ]; then
  echo "No installation found at /opt/vcl/config/docker-compose.yml"
  exit 1
fi

echo "This will stop and remove the n8n Docker stack."
read -rp "Continue? (y/N): " CONFIRM
if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
  echo "Aborted."
  exit 0
fi

echo "Stopping containers..."
cd /opt/vcl/config
docker compose down

echo "Containers stopped and removed."
echo ""

read -rp "Remove all data under /opt/vcl/? This is irreversible. (y/N): " REMOVE_DATA
if [ "$REMOVE_DATA" = "y" ] || [ "$REMOVE_DATA" = "Y" ]; then
  sudo rm -rf /opt/vcl
  echo "All data removed."
else
  echo "Data preserved at /opt/vcl/"
fi

echo ""
echo "Uninstall complete."
