#!/bin/bash
set -e

echo "[INFO] Post-boot setup started"

if systemctl list-unit-files | grep -q docker.service; then
  echo "[INFO] Starting Docker service..."
  sudo systemctl start docker
  sudo systemctl enable docker
fi

echo "[INFO] Post-boot script completed."
