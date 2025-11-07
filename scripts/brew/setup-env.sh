#!/bin/bash
set -e

USE_INSECURE_REQ="${1:-0}"
ENV_FILE="${2:-/tmp/brew_env}"

echo "[INFO] Setting up Homebrew environment (USE_INSECURE_REQ=${USE_INSECURE_REQ})"
echo "[INFO] Current user: $(whoami)"

if [ "${USE_INSECURE_REQ}" = "1" ]; then
    HOMEBREW_FORCE_BREWED_CURL=1
    HOMEBREW_NO_SSL=1
    HOMEBREW_INSTALL_FROM_API=1
    HOMEBREW_CURLRC=1
    HOMEBREW_CURL_SSL_VERIFY=0
    echo "[INFO] Homebrew SSL verification DISABLED"
else
    HOMEBREW_FORCE_BREWED_CURL=0
    HOMEBREW_NO_SSL=0
    HOMEBREW_INSTALL_FROM_API=0
    HOMEBREW_CURLRC=0
    HOMEBREW_CURL_SSL_VERIFY=1
    echo "[INFO] Homebrew SSL verification ENABLED"
fi

BREW_ENV_VARS="export HOMEBREW_FORCE_BREWED_CURL=${HOMEBREW_FORCE_BREWED_CURL}
export HOMEBREW_NO_SSL=${HOMEBREW_NO_SSL}
export HOMEBREW_INSTALL_FROM_API=${HOMEBREW_INSTALL_FROM_API}
export HOMEBREW_CURLRC=${HOMEBREW_CURLRC}
export HOMEBREW_CURL_SSL_VERIFY=${HOMEBREW_CURL_SSL_VERIFY}"

cat > "${ENV_FILE}" << EOF
${BREW_ENV_VARS}
EOF
chmod 644 "${ENV_FILE}"
echo "[INFO] User environment file created at ${ENV_FILE}"

SYSTEM_ENV_FILE="/etc/profile.d/homebrew-env.sh"
cat > "${SYSTEM_ENV_FILE}" << EOF
#!/bin/bash
# Homebrew environment configuration (available to all users)
${BREW_ENV_VARS}
EOF
chmod 644 "${SYSTEM_ENV_FILE}"
echo "[INFO] System environment file created at ${SYSTEM_ENV_FILE}"

sed -i '/^HOMEBREW_/d' /etc/environment
cat >> /etc/environment << EOF
HOMEBREW_FORCE_BREWED_CURL=${HOMEBREW_FORCE_BREWED_CURL}
HOMEBREW_NO_SSL=${HOMEBREW_NO_SSL}
HOMEBREW_INSTALL_FROM_API=${HOMEBREW_INSTALL_FROM_API}
HOMEBREW_CURLRC=${HOMEBREW_CURLRC}
HOMEBREW_CURL_SSL_VERIFY=${HOMEBREW_CURL_SSL_VERIFY}
EOF
echo "[INFO] Added to /etc/environment (available to all users)"

if [ -f /etc/bash.bashrc ]; then
    echo "[ -f /etc/profile.d/homebrew-env.sh ] && . /etc/profile.d/homebrew-env.sh" >> /etc/bash.bashrc
fi

if [ -f /etc/zsh/zshenv ]; then
    echo "[ -f /etc/profile.d/homebrew-env.sh ] && . /etc/profile.d/homebrew-env.sh" >> /etc/zsh/zshenv
fi

echo "[INFO] ========================================="
echo "[INFO] Homebrew configuration saved:"
echo "[INFO] ========================================="
echo "Locations:"
echo "  - ${ENV_FILE}"
echo "  - ${SYSTEM_ENV_FILE}"
echo "  - /etc/environment"
echo ""
echo "Variables:"
echo "${BREW_ENV_VARS}"
echo "[INFO] ========================================="
