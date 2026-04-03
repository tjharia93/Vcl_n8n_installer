#!/usr/bin/env bash
set -e

echo "[5/10] Generating .env..."

SCRIPT_DIR="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
source /tmp/vcl_installer_answers.env

ENV_FILE="/opt/vcl/config/.env"
N8N_ENCRYPTION_KEY="$(openssl rand -hex 32)"

# Start with core settings
cat > "$ENV_FILE" <<EOF
# ===========================================
# VCL n8n Configuration
# Generated: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Mode: $INSTALL_MODE
# ===========================================

# Core
N8N_HOST=$N8N_HOST
N8N_PORT=$N8N_PORT
N8N_PROTOCOL=http
GENERIC_TIMEZONE=$TZ_VALUE
TZ=$TZ_VALUE

# Security
N8N_BASIC_AUTH_ACTIVE=true
N8N_BASIC_AUTH_USER=$N8N_USER
N8N_BASIC_AUTH_PASSWORD=$N8N_PASS
N8N_ENCRYPTION_KEY=$N8N_ENCRYPTION_KEY

# Binary data
N8N_DEFAULT_BINARY_DATA_MODE=filesystem
EOF

# Database settings
if [ "$DB_CHOICE" = "postgres" ]; then
  DB_PASSWORD="$(openssl rand -hex 16)"
  cat >> "$ENV_FILE" <<EOF

# Database (PostgreSQL)
DB_TYPE=postgresdb
DB_POSTGRESDB_HOST=postgres
DB_POSTGRESDB_PORT=5432
DB_POSTGRESDB_DATABASE=n8n
DB_POSTGRESDB_USER=n8n
DB_POSTGRESDB_PASSWORD=$DB_PASSWORD
POSTGRES_DB=n8n
POSTGRES_USER=n8n
POSTGRES_PASSWORD=$DB_PASSWORD
EOF
else
  cat >> "$ENV_FILE" <<EOF

# Database (SQLite - default)
DB_TYPE=sqlite
EOF
fi

# Optional integrations
cat >> "$ENV_FILE" <<EOF

# OpenAI
OPENAI_API_KEY=${OPENAI_API_KEY:-}

# Zoho IMAP
ZOHO_IMAP_HOST=imap.zoho.com
ZOHO_IMAP_PORT=993
ZOHO_IMAP_USER=${ZOHO_IMAP_USER:-}
ZOHO_IMAP_PASSWORD=${ZOHO_IMAP_PASSWORD:-}
ZOHO_IMAP_SSL=true

# Alerts
ALERT_EMAIL_TO=${ALERT_EMAIL_TO:-}
EOF

chmod 600 "$ENV_FILE"

echo "  .env generated at $ENV_FILE"
echo "[5/10] .env ready."
