#!/bin/bash
set -euo pipefail

case "${1:-}" in
    detect)
        hour=$(date +%H)
        if (( hour >= 6 && hour < 12 )); then echo "morning"
        elif (( hour >= 12 && hour < 18 )); then echo "afternoon"
        elif (( hour >= 18 && hour < 22 )); then echo "evening"
        else echo "night"; fi
        ;;
    apply)
        ctx=$(context.sh detect)
        case "$ctx" in
            morning) hyprctl keyword decoration:blur:enabled true ;;
            afternoon) hyprctl keyword decoration:blur:enabled true ;;
            evening) hyprctl keyword decoration:blur:enabled true ;;
            night) hyprctl keyword decoration:blur:enabled true ;;
        esac
        ;;
    *) echo "Usage: context.sh [detect|apply]"; exit 1 ;;
esac