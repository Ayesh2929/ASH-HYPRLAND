#!/bin/bash
set -euo pipefail

case "${1:-}" in
    play-pause) playerctl play-pause ;;
    next) playerctl next ;;
    previous) playerctl previous ;;
    stop) playerctl stop ;;
    status) playerctl status ;;
    metadata) playerctl metadata --format '{{title}} - {{artist}}' ;;
    position) playerctl position ;;
    volume) playerctl volume "${2:-}" ;;
    *) echo "Usage: player.sh [play-pause|next|previous|stop|status|metadata|position|volume]"; exit 1 ;;
esac