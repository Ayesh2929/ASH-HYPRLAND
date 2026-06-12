#!/bin/bash
set -euo pipefail

case "${1:-}" in
    pretty) uptime -p ;;
    since) uptime -s ;;
    seconds) cat /proc/uptime | awk '{printf "%.0f", $1}' ;;
    *) echo "Usage: uptime.sh [pretty|since|seconds]"; exit 1 ;;
esac