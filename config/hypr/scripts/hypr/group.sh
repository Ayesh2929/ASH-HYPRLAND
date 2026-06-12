#!/bin/bash
set -euo pipefail

case "${1:-}" in
    toggle) hyprctl dispatch togglegroup ;;
    next) hyprctl dispatch changegroupactive next ;;
    prev) hyprctl dispatch changegroupactive prev ;;
    lock) hyprctl dispatch lockgroup ;;
    unlock) hyprctl dispatch unlockgroup ;;
    *) echo "Usage: group.sh [toggle|next|prev|lock|unlock]"; exit 1 ;;
esac