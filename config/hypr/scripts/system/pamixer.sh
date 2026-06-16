#!/bin/bash
set -euo pipefail

case "${1:-}" in
    up) pamixer -i 5 ;;
    down) pamixer -d 5 ;;
    mute) pamixer -t ;;
    set) pamixer --set-volume "${2:-50}" ;;
    get) pamixer --get-volume ;;
    *) echo "Usage: pamixer.sh [up|down|mute|set|get]"; exit 1 ;;
esac