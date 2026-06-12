#!/bin/bash
set -euo pipefail

case "${1:-}" in
    usage) df -h / | tail -1 | awk '{print $5}' ;;
    free) df -h / | tail -1 | awk '{print $4}' ;;
    total) df -h / | tail -1 | awk '{print $2}' ;;
    *) echo "Usage: disk.sh [usage|free|total]"; exit 1 ;;
esac