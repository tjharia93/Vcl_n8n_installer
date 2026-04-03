#!/usr/bin/env bash
set -e

echo "[6/10] Generating docker-compose.yml..."

SCRIPT_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source /tmp/vcl_installer_answers.env

TARGET="/opt/vcl/config/docker-compose.yml"

if [ "$DB_CHOICE" = "sqlite" ]; then
  cp "$SCRIPT_DIR/templates/docker-compose.sqlite.yml" "$TARGET"
  echo "  Using SQLite template."
else
  cp "$SCRIPT_DIR/templates/docker-compose.postgres.yml" "$TARGET"
  echo "  Using PostgreSQL template."
fi

echo "  docker-compose.yml created at $TARGET"
echo "[6/10] Compose file ready."
