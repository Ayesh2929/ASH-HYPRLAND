#!/bin/bash
set -euo pipefail

case "${1:-}" in
    create) hyprctl dispatch workspace "name:${2:-new}" ;;
    rename) hyprctl dispatch renameworkspace "$2" "$3" ;;
    remove) hyprctl dispatch destroyworkspace "$2" ;;
    list) hyprctl workspaces -j | jq -r '.[] | "\(.id): \(.name)"' ;;
    *) echo "Usage: virtual-desktop.sh [create|rename|remove|list]"; exit 1 ;;
esac