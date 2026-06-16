#!/bin/bash
set -euo pipefail

case "${1:-}" in
    toggle) hyprctl dispatch fullscreen ;;
    on) hyprctl dispatch fullscreen 1 ;;
    off) hyprctl dispatch fullscreen 0 ;;
    *) echo "Usage: fullscreen.sh [toggle|on|off]"; exit 1 ;;
esac