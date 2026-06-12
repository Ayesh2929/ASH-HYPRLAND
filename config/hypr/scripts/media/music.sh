#!/bin/bash
set -euo pipefail

case "${1:-}" in
    play) playerctl play ;;
    pause) playerctl pause ;;
    next) playerctl next ;;
    prev) playerctl previous ;;
    status) playerctl status ;;
    *) echo "Usage: music.sh [play|pause|next|prev|status]"; exit 1 ;;
esac