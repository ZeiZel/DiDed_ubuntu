#!/bin/bash
set -e

USE_INSECURE_REQ="${1:-0}"
ENV_FILE="${2:-$HOME/.brew_env}"

echo "[INFO] Setting up Homebrew environment (USE_INSECURE_REQ=${USE_INSECURE_REQ})"

if [ "${USE_INSECURE_REQ}" = "1" ]; then
    cat > "${ENV_FILE}" << 'EOF'
export HOMEBREW_FORCE_BREWED_CURL=1
export HOMEBREW_NO_SSL=1
export HOMEBREW_INSTALL_FROM_API=1
export HOMEBREW_CURLRC=1
export HOMEBREW_CURL_SSL_VERIFY=0
EOF
    echo "[INFO] Homebrew SSL verification DISABLED"
else
    cat > "${ENV_FILE}" << 'EOF'
export HOMEBREW_FORCE_BREWED_CURL=0
export HOMEBREW_NO_SSL=0
export HOMEBREW_INSTALL_FROM_API=0
export HOMEBREW_CURLRC=0
export HOMEBREW_CURL_SSL_VERIFY=1
EOF
    echo "[INFO] Homebrew SSL verification ENABLED"
fi

chmod 644 "${ENV_FILE}"
echo "[INFO] Environment file created at ${ENV_FILE}:"
cat "${ENV_FILE}"
