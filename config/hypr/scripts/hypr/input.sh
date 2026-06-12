#!/bin/bash
set -euo pipefail

case "${1:-}" in
    keyboard)
        hyprctl keyword input:kb_layout "${2:-us}"
        hyprctl keyword input:kb_variant "${3:-}"
        ;;
    mouse)
        hyprctl keyword input:sensitivity "${2:-0}"
        hyprctl keyword input:accel_profile "${3:-flat}"
        ;;
    touchpad)
        hyprctl keyword input:touchpad:natural_scroll "${2:-false}"
        hyprctl keyword input:touchpad:tap_to_click "${3:-true}"
        ;;
    *) echo "Usage: input.sh [keyboard|mouse|touchpad]"; exit 1 ;;
esac