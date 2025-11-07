#!/bin/bash
set -e

USERNAME="${USERNAME:-root}"

echo "[INFO] Loading saved environment variables"

if [ -f /etc/profile.d/homebrew-env.sh ]; then
    echo "[INFO] Found Homebrew environment configuration"
    echo "[INFO] Current Homebrew settings:"
    cat /etc/profile.d/homebrew-env.sh
fi

if grep -q "USE_INSECURE_REQ=" /etc/environment; then
    USE_INSECURE_REQ=$(grep "USE_INSECURE_REQ=" /etc/environment | cut -d= -f2)
    echo "[INFO] USE_INSECURE_REQ is set to: $USE_INSECURE_REQ"
fi

echo "[INFO] Environment variables loaded successfully"
exit 0
