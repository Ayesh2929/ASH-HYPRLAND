#!/bin/bash
set -euo pipefail

case "${1:-}" in
    play) mpv "${2:-}" ;;
    socket) echo '{ "command": ["get_property", "time-pos"] }' | socat - /tmp/mpv-socket ;;
    pause) echo '{ "command": ["set_property", "pause", true] }' | socat - /tmp/mpv-socket ;;
    resume) echo '{ "command": ["set_property", "pause", false] }' | socat - /tmp/mpv-socket ;;
    *) echo "Usage: mpv.sh [play|socket|pause|resume]"; exit 1 ;;
esac