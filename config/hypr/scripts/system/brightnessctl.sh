#!/bin/bash
set -euo pipefail

case "${1:-}" in
    up) brightnessctl set 5%+ ;;
    down) brightnessctl set 5%- ;;
    set) brightnessctl set "${2:-50}%" ;;
    get) brightnessctl get ;;
    max) brightnessctl max ;;
    *) echo "Usage: brightnessctl.sh [up|down|set|get|max]"; exit 1 ;;
esac