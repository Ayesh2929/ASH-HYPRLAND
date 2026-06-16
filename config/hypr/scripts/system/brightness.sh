#!/bin/bash
set -euo pipefail

case "${1:-}" in
    up) brightnessctl set 10%+ ;;
    down) brightnessctl set 10%- ;;
    set) brightnessctl set "${2:-50}%" ;;
    get) brightnessctl get ;;
    *) echo "Usage: brightness.sh [up|down|set|get]"; exit 1 ;;
esac