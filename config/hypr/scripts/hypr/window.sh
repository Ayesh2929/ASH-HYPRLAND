#!/bin/bash
set -euo pipefail

case "${1:-}" in
    float) hyprctl dispatch togglefloating ;;
    fullscreen) hyprctl dispatch fullscreen ;;
    pin) hyprctl dispatch pin ;;
    move-left) hyprctl dispatch movewindow l ;;
    move-right) hyprctl dispatch movewindow r ;;
    move-up) hyprctl dispatch movewindow u ;;
    move-down) hyprctl dispatch movewindow d ;;
    resize-left) hyprctl dispatch resizeactive -10 0 ;;
    resize-right) hyprctl dispatch resizeactive 10 0 ;;
    resize-up) hyprctl dispatch resizeactive 0 -10 ;;
    resize-down) hyprctl dispatch resizeactive 0 10 ;;
    *) echo "Usage: window.sh [float|fullscreen|pin|move-*|resize-*]"; exit 1 ;;
esac