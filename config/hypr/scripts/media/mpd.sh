#!/bin/bash
set -euo pipefail

case "${1:-}" in
    play) mpc play ;;
    pause) mpc pause ;;
    next) mpc next ;;
    prev) mpc prev ;;
    stop) mpc stop ;;
    status) mpc status ;;
    current) mpc current ;;
    volume) mpc volume "${2:-}" ;;
    add) mpc add "$2" ;;
    clear) mpc clear ;;
    *) echo "Usage: mpd.sh [play|pause|next|prev|stop|status|current|volume|add|clear]"; exit 1 ;;
esac