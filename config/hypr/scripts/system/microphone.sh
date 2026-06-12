#!/bin/bash
set -euo pipefail

case "${1:-}" in
    mute) pactl set-source-mute @DEFAULT_SOURCE@ toggle ;;
    volume) pactl set-source-volume @DEFAULT_SOURCE@ "${2:-50}%" ;;
    status) pactl get-source-volume @DEFAULT_SOURCE@ ;;
    *) echo "Usage: microphone.sh [mute|volume|status]"; exit 1 ;;
esac