#!/bin/bash
set -euo pipefail

case "${1:-}" in
    log) hyprctl dispatch exec "tail -f ~/.local/share/hyprland/hyprland.log" ;;
    reload-log) hyprctl reload && sleep 1 && tail -20 ~/.local/share/hyprland/hyprland.log ;;
    binds) hyprctl binds ;;
    devices) hyprctl devices ;;
    layers) hyprctl layers ;;
    clients) hyprctl clients -j ;;
    workspaces) hyprctl workspaces -j ;;
    *) echo "Usage: debug.sh [log|reload-log|binds|devices|layers|clients|workspaces]"; exit 1 ;;
esac