#!/bin/bash
set -euo pipefail

case "${1:-}" in
    usage) top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d '%' ;;
    temp) sensors | grep "Package id 0" | awk '{print $4}' | tr -d '+°C' ;;
    freq) cat /proc/cpuinfo | grep "cpu MHz" | head -1 | awk '{print $4}' ;;
    gov) cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ;;
    *) echo "Usage: cpu.sh [usage|temp|freq|gov]"; exit 1 ;;
esac