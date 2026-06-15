#!/bin/bash
set -euo pipefail

case "${1:-}" in
    list) hyprctl monitors -j ;;
    active) hyprctl monitors -j | jq -r '.[] | select(.focused==true) | .name' ;;
    add) hyprctl keyword monitor "$2" ;;
    remove) hyprctl keyword monitor "$2,disable" ;;
    scale) hyprctl keyword monitor "$2,scale,$3" ;;
    *) echo "Usage: monitor.sh [list|active|add|remove|scale]"; exit 1 ;;
esac