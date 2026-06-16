#!/bin/bash
set -euo pipefail

case "${1:-}" in
    next) hyprctl dispatch workspace e+1 ;;
    prev) hyprctl dispatch workspace e-1 ;;
    move-next) hyprctl dispatch movetoworkspace e+1 ;;
    move-prev) hyprctl dispatch movetoworkspace e-1 ;;
    list) hyprctl workspaces -j ;;
    *) echo "Usage: workspace.sh [next|prev|move-next|move-prev|list]"; exit 1 ;;
esac