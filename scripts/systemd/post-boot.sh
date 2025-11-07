#!/bin/bash
set -e

USERNAME="${USERNAME:-root}"
SHELL_PATH="/bin/zsh"

echo "[INFO] Post-boot setup started"
echo "[INFO] USERNAME: $USERNAME"

if [ -f /etc/profile.d/homebrew-env.sh ]; then
    echo "[INFO] Loading Homebrew environment variables"
    . /etc/profile.d/homebrew-env.sh
fi

# 1. zsh as default
if id "$USERNAME" &>/dev/null; then
    echo "[INFO] Setting default shell to zsh for user $USERNAME"
    chsh -s "$SHELL_PATH" "$USERNAME" || echo "[WARN] Failed to change shell with chsh"

    CURRENT_SHELL=$(getent passwd "$USERNAME" | cut -d: -f7)
    echo "[INFO] Current shell for $USERNAME: $CURRENT_SHELL"
else
    echo "[WARN] User $USERNAME not found"
fi

# 2. setting getty
if [ -d /etc/systemd/system/getty.target.wants ]; then
    echo "[INFO] Setting up autologin for $USERNAME"

    mkdir -p /etc/systemd/system/getty@tty1.service.d

    cat > /etc/systemd/system/getty@tty1.service.d/override.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USERNAME --noclear %I \$TERM
Type=idle
EOF

    systemctl daemon-reload
    echo "[INFO] Autologin configured for tty1"
fi

# 3. Enable docker daemon
if systemctl list-unit-files | grep -q docker.service; then
    echo "[INFO] Docker service found"

    if ! systemctl is-active --quiet docker; then
        echo "[INFO] Starting Docker service..."
        systemctl start docker 2>&1 || echo "[WARN] Failed to start docker (expected in some environments)"
    fi

    systemctl enable docker || echo "[WARN] Failed to enable docker"
fi

echo "[INFO] ========================================="
echo "[INFO] Post-boot setup completed"
echo "[INFO] ========================================="
exit 0
