#!/bin/bash
set -euo pipefail

case "${1:-}" in
    start) gnome-network-displays &
    stop) pkill -f gnome-network-displays ;;
    *) echo "Usage: cast.sh [start|stop]"; exit 1 ;;
esac