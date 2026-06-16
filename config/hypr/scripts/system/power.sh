#!/bin/bash
set -euo pipefail

case "${1:-}" in
    lock) swaylock ;;
    logout) hyprctl dispatch exit ;;
    suspend) systemctl suspend ;;
    hibernate) systemctl hibernate ;;
    reboot) systemctl reboot ;;
    shutdown) systemctl poweroff ;;
    *) echo "Usage: power.sh [lock|logout|suspend|hibernate|reboot|shutdown]"; exit 1 ;;
esac