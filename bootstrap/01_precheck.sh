#!/usr/bin/env bash
set -e

echo "[1/10] Running pre-checks..."

# Check Ubuntu
if ! grep -qi ubuntu /etc/os-release 2>/dev/null; then
  echo "ERROR: This installer supports Ubuntu only."
  exit 1
fi

# Check supported version
UBUNTU_VERSION=$(. /etc/os-release && echo "$VERSION_ID")
case "$UBUNTU_VERSION" in
  22.04|24.04)
    echo "  Ubuntu $UBUNTU_VERSION detected."
    ;;
  *)
    echo "WARNING: Ubuntu $UBUNTU_VERSION is not officially tested. Supported: 22.04, 24.04."
    read -rp "  Continue anyway? (y/N): " CONTINUE
    if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
      exit 1
    fi
    ;;
esac

# Check sudo
if ! command -v sudo >/dev/null 2>&1; then
  echo "ERROR: sudo is required."
  exit 1
fi

# Check internet
if ! curl -fsS --max-time 5 https://get.docker.com >/dev/null 2>&1; then
  echo "ERROR: No internet access detected."
  exit 1
fi

# Install curl if missing
if ! command -v curl >/dev/null 2>&1; then
  echo "  Installing curl..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq curl
fi

# Install git if missing
if ! command -v git >/dev/null 2>&1; then
  echo "  Installing git..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq git
fi

# Check disk space (require at least 5GB free on /)
AVAILABLE_KB=$(df / | awk 'NR==2 {print $4}')
REQUIRED_KB=5242880
if [ "$AVAILABLE_KB" -lt "$REQUIRED_KB" ]; then
  echo "ERROR: Insufficient disk space. Need at least 5GB free, have $(( AVAILABLE_KB / 1048576 ))GB."
  exit 1
fi

echo "[1/10] Pre-checks passed."
