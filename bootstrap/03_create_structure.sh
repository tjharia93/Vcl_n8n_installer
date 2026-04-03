#!/usr/bin/env bash
set -e

echo "[3/10] Creating folder structure..."

sudo mkdir -p /opt/vcl/{installer,apps,runtime,config}
sudo mkdir -p /opt/vcl/runtime/{n8n_data,postgres_data,backups,logs,files}
sudo mkdir -p /opt/vcl/runtime/files/{inbox_files,processed,review,failed,exports}

sudo chown -R "$USER":"$USER" /opt/vcl

echo "  /opt/vcl/ structure created."
echo "[3/10] Folder structure ready."
