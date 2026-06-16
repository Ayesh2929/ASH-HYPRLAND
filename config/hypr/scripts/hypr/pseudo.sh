#!/bin/bash
set -euo pipefail

case "${1:-}" in
    toggle) hyprctl dispatch pseudo ;;
    on) hyprctl dispatch pseudo 1 ;;
    off) hyprctl dispatch pseudo 0 ;;
    *) echo "Usage: pseudo.sh [toggle|on|off]"; exit 1 ;;
esac