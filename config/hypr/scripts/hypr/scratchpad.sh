#!/bin/bash
set -euo pipefail

case "${1:-}" in
    show) hyprctl dispatch togglespecialworkspace scratchpad ;;
    add) hyprctl dispatch movetoworkspacespecial scratchpad ;;
    remove) hyprctl dispatch movetoworkspace "$2" ;;
    *) echo "Usage: scratchpad.sh [show|add|remove]"; exit 1 ;;
esac