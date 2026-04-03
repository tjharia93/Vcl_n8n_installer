#!/usr/bin/env bash
set -e

echo "[8/10] Running health checks..."

source /tmp/vcl_installer_answers.env

MAX_RETRIES=6
RETRY_INTERVAL=5
URL="http://${N8N_HOST}:${N8N_PORT}"

echo "  Waiting for n8n at $URL ..."

for i in $(seq 1 $MAX_RETRIES); do
  if curl -fsS --max-time 5 "$URL" >/dev/null 2>&1; then
    echo "  n8n is reachable at $URL"
    echo "[8/10] Health check passed."
    exit 0
  fi
  echo "  Attempt $i/$MAX_RETRIES - not ready yet, waiting ${RETRY_INTERVAL}s..."
  sleep "$RETRY_INTERVAL"
done

echo ""
echo "  WARNING: n8n did not respond after $(( MAX_RETRIES * RETRY_INTERVAL ))s."
echo "  This may be normal on first startup (image pull, DB migration)."
echo "  Check logs with: cd /opt/vcl/config && docker compose logs -f"
echo ""
echo "[8/10] Health check did not pass (n8n may still be starting)."
