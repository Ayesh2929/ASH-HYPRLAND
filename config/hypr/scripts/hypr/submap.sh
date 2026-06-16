#!/bin/bash
set -euo pipefail

case "${1:-}" in
    resize) hyprctl dispatch submap resize ;;
    move) hyprctl dispatch submap move ;;
    *) echo "Usage: submap.sh [resize|move]"; exit 1 ;;
esac