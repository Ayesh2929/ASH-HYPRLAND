#!/bin/bash
set -euo pipefail

SAVE_DIR="${HOME}/Pictures/screenshots"
mkdir -p "${SAVE_DIR}"

case "${1:-}" in
    region)
        grim -g "$(slurp)" "${SAVE_DIR}/$(date +%s).png"
        ;;
    full)
        grim "${SAVE_DIR}/$(date +%s).png"
        ;;
    window)
        hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"' | grim -g - "${SAVE_DIR}/$(date +%s).png"
        ;;
    clipboard)
        grim -g "$(slurp)" - | wl-copy
        ;;
    *)
        echo "Usage: screenshot.sh [region|full|window|clipboard]"
        exit 1
        ;;
esac