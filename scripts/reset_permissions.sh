#!/usr/bin/env bash
set -e

echo "Resetting permissions on /opt/vcl/..."

sudo chown -R "$USER":"$USER" /opt/vcl
chmod 600 /opt/vcl/config/.env 2>/dev/null || true

echo "Permissions reset."
