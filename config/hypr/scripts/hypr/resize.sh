#!/bin/bash
set -euo pipefail

case "${1:-}" in
    left) hyprctl dispatch resizeactive -10 0 ;;
    right) hyprctl dispatch resizeactive 10 0 ;;
    up) hyprctl dispatch resizeactive 0 -10 ;;
    down) hyprctl dispatch resizeactive 0 10 ;;
    *) echo "Usage: resize.sh [left|right|up|down]"; exit 1 ;;
esac