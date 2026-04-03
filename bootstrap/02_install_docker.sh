#!/usr/bin/env bash
set -e

echo "[2/10] Checking Docker..."

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  echo "  Docker and Docker Compose already installed."
  docker --version
  docker compose version
  echo "[2/10] Docker ready."
  exit 0
fi

echo "  Installing Docker..."

sudo apt-get update -qq
sudo apt-get install -y -qq ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -qq
sudo apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER" || true

echo "  Docker installed successfully."
docker --version
docker compose version

echo ""
echo "  NOTE: If this is a fresh Docker install, you may need to log out"
echo "  and back in for group changes to take effect."
echo ""

echo "[2/10] Docker ready."
