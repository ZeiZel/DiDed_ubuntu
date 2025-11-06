#!/bin/bash
set -e

PROXY_URL="${1}"
PROXY_PORT="${2}"
ENV_FILE="${3:-/etc/environment}"

echo "Setting up proxy configuration"

if [ -n "${PROXY_URL}" ]; then
    echo "Using proxy URL: ${PROXY_URL}"
    echo "export HTTPS_PROXY=${PROXY_URL}" >> "${ENV_FILE}"
    echo "export HTTP_PROXY=${PROXY_URL}" >> "${ENV_FILE}"
elif [ -n "${PROXY_PORT}" ]; then
    echo "Using proxy port: ${PROXY_PORT}"
    echo "export HTTPS_PROXY=http://host.docker.internal:${PROXY_PORT}" >> "${ENV_FILE}"
    echo "export HTTP_PROXY=http://host.docker.internal:${PROXY_PORT}" >> "${ENV_FILE}"
else
    echo "No proxy configured"
fi

if [ -f "${ENV_FILE}" ]; then
    echo "Proxy configuration:"
    grep -E "PROXY" "${ENV_FILE}" || echo "No proxy set"
fi
