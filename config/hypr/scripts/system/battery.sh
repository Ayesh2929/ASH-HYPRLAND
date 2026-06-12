#!/bin/bash
set -euo pipefail

case "${1:-}" in
    status)
        cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1
        ;;
    charging)
        cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -1
        ;;
    health)
        cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1
        ;;
    *) echo "Usage: battery.sh [status|charging|health]"; exit 1 ;;
esac