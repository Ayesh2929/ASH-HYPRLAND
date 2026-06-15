#!/bin/bash
set -euo pipefail

case "${1:-}" in
    usage) free | grep Mem | awk '{printf "%.1f", $3/$2 * 100}' ;;
    free) free -h | grep Mem | awk '{print $4}' ;;
    total) free -h | grep Mem | awk '{print $2}' ;;
    swap) free -h | grep Swap | awk '{print $3 "/" $2}' ;;
    *) echo "Usage: memory.sh [usage|free|total|swap]"; exit 1 ;;
esac