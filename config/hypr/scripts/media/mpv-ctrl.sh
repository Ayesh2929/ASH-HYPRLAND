#!/bin/bash
set -euo pipefail

SOCKET="/tmp/mpv-socket"

send_cmd() {
    echo "$1" | socat - "$SOCKET" 2>/dev/null
}

case "${1:-}" in
    play-pause) send_cmd '{ "command": ["set_property", "pause", true] }' ;;
    pause) send_cmd '{ "command": ["set_property", "pause", true] }' ;;
    resume) send_cmd '{ "command": ["set_property", "pause", false] }' ;;
    seek-fwd) send_cmd '{ "command": ["seek", 10] }' ;;
    seek-back) send_cmd '{ "command": ["seek", -10] }' ;;
    volume-up) send_cmd '{ "command": ["add", "volume", 5] }' ;;
    volume-down) send_cmd '{ "command": ["add", "volume", -5] }' ;;
    mute) send_cmd '{ "command": ["set_property", "mute", true] }' ;;
    unmute) send_cmd '{ "command": ["set_property", "mute", false] }' ;;
    fullscreen) send_cmd '{ "command": ["set_property", "fullscreen", true] }' ;;
    *) echo "Usage: mpv-ctrl.sh [play-pause|pause|resume|seek-fwd|seek-back|volume-up|volume-down|mute|unmute|fullscreen]"; exit 1 ;;
esac