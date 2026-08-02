#!/usr/bin/env bash
# Show the Reolink doorbell camera feed via mpv (low-latency RTSP).
# Credentials are kept outside the repo at ~/.config/doorbell-cam/credentials
# (chmod 600, one-time setup per machine, never committed to git):
#
#   DOORBELL_USER=admin
#   DOORBELL_PASS='your-password'
#   DOORBELL_IP=192.168.1.174

set -euo pipefail

CRED_FILE="$HOME/.config/doorbell-cam/credentials"

if [[ ! -f "$CRED_FILE" ]]; then
    notify-send "Doorbell camera" "Missing credentials file: $CRED_FILE" 2>/dev/null || true
    echo "Missing credentials file: $CRED_FILE" >&2
    exit 1
fi

# shellcheck source=/dev/null
source "$CRED_FILE"

exec mpv --rtsp-transport=tcp --profile=low-latency --untimed --no-cache \
    "rtsp://${DOORBELL_USER}:${DOORBELL_PASS}@${DOORBELL_IP}:554/h264Preview_01_main"
