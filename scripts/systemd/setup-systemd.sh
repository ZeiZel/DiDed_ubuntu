#!/bin/bash
set -e

USERNAME="${1:-root}"
POST_BOOT_SCRIPT="${2:-/usr/local/bin/post-boot.sh}"

echo "[INFO] Setting up systemd post-boot service for user: $USERNAME"

# check existed
if [ ! -f "$POST_BOOT_SCRIPT" ]; then
    echo "[ERROR] Post-boot script not found at $POST_BOOT_SCRIPT"
    exit 1
fi

# check executable
if [ ! -x "$POST_BOOT_SCRIPT" ]; then
    chmod +x "$POST_BOOT_SCRIPT"
    echo "[INFO] Made script executable"
fi

# create systemd service
echo "[INFO] Creating systemd service file"
cat > /etc/systemd/system/post-boot.service << EOF
[Unit]
Description=Post-Boot Initialization Script
After=multi-user.target
Wants=network-online.target
After=network-online.target

[Service]
Type=oneshot
ExecStart=${POST_BOOT_SCRIPT}
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
Environment="USERNAME=${USERNAME}"

[Install]
WantedBy=multi-user.target
EOF

# check syntax
echo "[INFO] Validating systemd service"
systemd-analyze verify /etc/systemd/system/post-boot.service || echo "[WARN] Service validation issues"

# enable service
echo "[INFO] Enabling post-boot service"
systemctl enable post-boot.service

echo "[INFO] Systemd setup completed"
exit 0
