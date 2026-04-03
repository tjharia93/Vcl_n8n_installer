#!/usr/bin/env bash
set -e

echo "[9/10] Cloning app repo..."

source /tmp/vcl_installer_answers.env

APP_DIR="/opt/vcl/apps/vcl-email-automation"

if [ -z "$APP_REPO_URL" ]; then
  echo "  No Repo 2 URL provided. Skipping."
  echo "[9/10] Skipped."
  exit 0
fi

if [ -d "$APP_DIR/.git" ]; then
  echo "  Repo 2 already exists at $APP_DIR. Pulling latest..."
  git -C "$APP_DIR" pull
else
  echo "  Cloning $APP_REPO_URL..."
  git clone "$APP_REPO_URL" "$APP_DIR"
fi

echo "  App repo ready at $APP_DIR"
echo "[9/10] Clone complete."
