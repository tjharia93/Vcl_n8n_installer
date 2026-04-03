#!/usr/bin/env bash
set -e

echo "[4/10] Collecting configuration..."
echo ""

CONFIG_TMP="/tmp/vcl_installer_answers.env"
rm -f "$CONFIG_TMP"

# Install mode
echo "Install mode:"
echo "  1. Test (SQLite, relaxed settings)"
echo "  2. Production (PostgreSQL, recommended)"
read -rp "Choose [2]: " MODE_CHOICE
MODE_CHOICE=${MODE_CHOICE:-2}
if [ "$MODE_CHOICE" = "1" ]; then
  INSTALL_MODE="test"
else
  INSTALL_MODE="production"
fi

# Database
if [ "$INSTALL_MODE" = "test" ]; then
  DB_CHOICE="sqlite"
  echo "  Using SQLite for test mode."
else
  echo ""
  echo "Database:"
  echo "  1. SQLite"
  echo "  2. PostgreSQL (recommended)"
  read -rp "Choose [2]: " DB_NUM
  DB_NUM=${DB_NUM:-2}
  if [ "$DB_NUM" = "1" ]; then
    DB_CHOICE="sqlite"
  else
    DB_CHOICE="postgres"
  fi
fi

echo ""
read -rp "n8n host/IP [localhost]: " N8N_HOST
N8N_HOST=${N8N_HOST:-localhost}

read -rp "n8n port [5678]: " N8N_PORT
N8N_PORT=${N8N_PORT:-5678}

read -rp "Timezone [Africa/Nairobi]: " TZ_VALUE
TZ_VALUE=${TZ_VALUE:-Africa/Nairobi}

echo ""
read -rp "n8n admin username [admin]: " N8N_USER
N8N_USER=${N8N_USER:-admin}

while true; do
  read -srp "n8n admin password: " N8N_PASS
  echo
  if [ -z "$N8N_PASS" ]; then
    echo "  Password cannot be empty."
  else
    break
  fi
done

echo ""
read -srp "OpenAI API key (press Enter to skip): " OPENAI_API_KEY
echo

echo ""
read -rp "Zoho IMAP email (press Enter to skip): " ZOHO_IMAP_USER
if [ -n "$ZOHO_IMAP_USER" ]; then
  read -srp "Zoho IMAP password/app password: " ZOHO_IMAP_PASSWORD
  echo
else
  ZOHO_IMAP_PASSWORD=""
fi

echo ""
read -rp "Alert email address (press Enter to skip): " ALERT_EMAIL_TO

echo ""
read -rp "Repo 2 URL (press Enter to skip): " APP_REPO_URL

cat > "$CONFIG_TMP" <<EOF
INSTALL_MODE=$INSTALL_MODE
DB_CHOICE=$DB_CHOICE
N8N_HOST=$N8N_HOST
N8N_PORT=$N8N_PORT
TZ_VALUE=$TZ_VALUE
N8N_USER=$N8N_USER
N8N_PASS=$N8N_PASS
OPENAI_API_KEY=$OPENAI_API_KEY
ZOHO_IMAP_USER=$ZOHO_IMAP_USER
ZOHO_IMAP_PASSWORD=$ZOHO_IMAP_PASSWORD
ALERT_EMAIL_TO=$ALERT_EMAIL_TO
APP_REPO_URL=$APP_REPO_URL
EOF

chmod 600 "$CONFIG_TMP"

echo ""
echo "[4/10] Configuration collected."
