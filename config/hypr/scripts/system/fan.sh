#!/bin/bash
set -euo pipefail

case "${1:-}" in
    speed) sensors | grep "fan" | awk '{print $2}' ;;
    max) cat /sys/class/hwmon/hwmon*/fan*_max 2>/dev/null | head -1 ;;
    *) echo "Usage: fan.sh [speed|max]"; exit 1 ;;
esac