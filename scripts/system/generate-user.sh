#!/bin/bash
set -e

# args
USERNAME="${1:-${USERNAME}}"
USER_UID="${2:-${USER_UID}}"
USER_GID="${3:-${USER_GID}}"
USER_PASSWORD="${4:-${USER_PASSWORD}}"

# validation
if [ -z "$USERNAME" ] || [ -z "$USER_UID" ] || [ -z "$USER_GID" ]; then
    echo "[ERROR] Missing required parameters"
    echo "Usage: $0 <username> <uid> <gid> [password]"
    echo "Or set USERNAME, USER_UID, USER_GID environment variables"
    exit 1
fi

echo "[INFO] ========================================="
echo "[INFO] Generating User"
echo "[INFO] ========================================="
echo "[INFO] Username: $USERNAME"
echo "[INFO] UID: $USER_UID"
echo "[INFO] GID: $USER_GID"
echo "[INFO] Password: $([ -n "$USER_PASSWORD" ] && echo 'SET' || echo 'NOT SET')"
echo "[INFO] ========================================="

# adding docker group
if ! getent group docker >/dev/null; then
    echo "[INFO] Creating docker group (GID: 999)"
    groupadd -g 999 docker
else
    echo "[INFO] Docker group already exists"
fi

# Create/rename user group
if getent group ${USER_GID} >/dev/null; then
    existing_group=$(getent group ${USER_GID} | cut -d: -f1)
    if [ "${existing_group}" != "${USERNAME}" ]; then
        echo "[INFO] Renaming group '${existing_group}' to '${USERNAME}'"
        groupmod -n ${USERNAME} ${existing_group}
    else
        echo "[INFO] Group '${USERNAME}' already exists with GID ${USER_GID}"
    fi
else
    echo "[INFO] Creating group '${USERNAME}' with GID ${USER_GID}"
    groupadd --gid ${USER_GID} ${USERNAME}
fi

# remove conflict user
if getent passwd ${USER_UID} >/dev/null; then
    existing_user=$(getent passwd ${USER_UID} | cut -d: -f1)
    if [ "${existing_user}" != "${USERNAME}" ]; then
        echo "[WARN] Removing existing user '${existing_user}' with UID ${USER_UID}"
        userdel -r ${existing_user} 2>/dev/null || true
    fi
fi

# adding user
if ! getent passwd ${USERNAME} >/dev/null; then
    echo "[INFO] Creating user '${USERNAME}'"
    useradd \
        --uid ${USER_UID} \
        --gid ${USER_GID} \
        --create-home \
        --shell /bin/zsh \
        --comment "Docker user" \
        ${USERNAME}
else
    echo "[INFO] User '${USERNAME}' already exists"
fi

# adding into sudoers with NOPASSWD
echo "[INFO] Configuring sudo for ${USERNAME}"
if ! grep -q "^${USERNAME} ALL=(ALL) NOPASSWD:ALL" /etc/sudoers 2>/dev/null; then
    echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
else
    echo "[INFO] ${USERNAME} already configured in sudoers"
fi

# setting password
if [ -n "${USER_PASSWORD}" ]; then
    echo "[INFO] Setting password"
    echo "${USERNAME}:${USER_PASSWORD}" | chpasswd
else
    echo "[WARN] No password provided"
fi

# add into group
echo "[INFO] Adding ${USERNAME} to groups: sudo, docker"
usermod -aG sudo,docker ${USERNAME}

# Валидация sudoers
echo "[INFO] Validating sudoers configuration"
if visudo -c; then
    echo "[SUCCESS] sudoers validation passed"
else
    echo "[ERROR] sudoers validation failed!"
    exit 1
fi

# info
echo "[SUCCESS] ========================================="
echo "[SUCCESS] User created successfully"
echo "[SUCCESS] ========================================="
echo "User info:"
getent passwd ${USERNAME}
echo ""
echo "Groups:"
groups ${USERNAME}
echo "[SUCCESS] ========================================="

exit 0
