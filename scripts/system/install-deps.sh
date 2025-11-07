#!/bin/bash
set -e

echo "[INFO] ========================================="
echo "[INFO] Installing System Dependencies"
echo "[INFO] ========================================="

echo "[INFO] Updating package repositories..."
apt-get update

echo "[INFO] Cleaning up old packages..."
apt-get autoremove -y
apt-get clean

echo "[INFO] Installing core utilities..."
apt-get install -y \
    sudo \
    curl \
    wget \
    gnupg \
    apt-transport-https \
    ca-certificates \
    xz-utils \
    unzip \
    zip \
    iputils-ping \
    build-essential \
    --no-install-recommends

echo "[INFO] Installing Git and CLI tools..."
apt-get install -y \
    git \
    gh \
    glab \
    --no-install-recommends

echo "[INFO] Installing Python..."
apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    --no-install-recommends

echo "[INFO] Installing text editors and search tools..."
apt-get install -y \
    nano \
    less \
    bash \
    make \
    gcc \
    cargo \
    bc \
    ed \
    gawk \
    findutils \
    diffutils \
    coreutils \
    --no-install-recommends

echo "[INFO] Installing additional tools..."
apt-get install -y \
    fd-find \
    ripgrep \
    zoxide \
    jq \
    yq \
    poppler-utils \
    imagemagick \
    ffmpeg \
    ffmpegthumbnailer \
    p7zip-full \
    atool \
    watch \
    --no-install-recommends

echo "[INFO] Installing system monitoring tools..."
apt-get install -y \
    btop \
    htop \
    thefuck \
    stow \
    eza \
    fzf \
    --no-install-recommends

echo "[INFO] Installing Zsh and plugins..."
apt-get install -y \
    zsh \
    zsh-antigen \
    zsh-syntax-highlighting \
    zsh-autosuggestions \
    --no-install-recommends

echo "[INFO] Installing development tools..."
apt-get install -y \
    golang-go \
    nodejs \
    npm \
    --no-install-recommends

echo "[INFO] Creating symlinks for GNU tools..."
ln -sf /usr/bin/fd   /usr/local/bin/fd
ln -sf /usr/bin/grep /usr/bin/ggrep
ln -sf /usr/bin/sed  /usr/bin/gsed
ln -sf /usr/bin/tar  /usr/bin/gtar

echo "[INFO] Cleaning up package manager..."
rm -rf /var/lib/apt/lists/*
update-ca-certificates --fresh

echo "[SUCCESS] ========================================="
echo "[SUCCESS] Dependencies installed successfully"
echo "[SUCCESS] ========================================="

exit 0
