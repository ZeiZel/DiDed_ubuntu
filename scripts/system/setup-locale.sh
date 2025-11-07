#!/bin/bash
set -e

echo "[INFO] Updating locales"

apt-get update && \
apt-get install -y locales && \
locale-gen en_US.UTF-8 && \
locale-gen ru_RU.UTF-8 && \
update-locale LANG=en_US.UTF-8 LC_MESSAGES=POSIX && \
rm -rf /var/lib/apt/lists/*

echo "[INFO] Locales updated successfully!"
