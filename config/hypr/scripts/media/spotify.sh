#!/bin/bash
set -euo pipefail

case "${1:-}" in
    play) playerctl -p spotify play ;;
    pause) playerctl -p spotify pause ;;
    next) playerctl -p spotify next ;;
    previous) playerctl -p spotify previous ;;
    status) playerctl -p spotify status ;;
    metadata) playerctl -p spotify metadata --format '{{title}} - {{artist}}' ;;
    *) echo "Usage: spotify.sh [play|pause|next|previous|status|metadata]"; exit 1 ;;
esac