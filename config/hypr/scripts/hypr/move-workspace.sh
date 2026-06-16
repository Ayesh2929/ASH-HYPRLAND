#!/bin/bash
set -euo pipefail

case "${1:-}" in
    left) hyprctl dispatch movewindow l ;;
    right) hyprctl dispatch movewindow r ;;
    up) hyprctl dispatch movewindow u ;;
    down) hyprctl dispatch movewindow d ;;
    ws) hyprctl dispatch movetoworkspace "$2" ;;
    special) hyprctl dispatch movetoworkspacespecial "$2" ;;
    *) echo "Usage: move-workspace.sh [left|right|up|down|ws|special]"; exit 1 ;;
esac