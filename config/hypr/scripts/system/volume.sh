#!/bin/bash
set -euo pipefail

case "${1:-}" in
    up) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ ;;
    down) wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- ;;
    mute) wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
    set) wpctl set-volume @DEFAULT_AUDIO_SINK@ "${2:-50}%" ;;
    get) wpctl get-volume @DEFAULT_AUDIO_SINK@ ;;
    *) echo "Usage: volume.sh [up|down|mute|set|get]"; exit 1 ;;
esac