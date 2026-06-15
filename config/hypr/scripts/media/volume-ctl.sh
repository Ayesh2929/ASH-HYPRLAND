#!/bin/bash
set -euo pipefail

case "${1:-}" in
    up) pactl set-sink-volume @DEFAULT_SINK@ +5% ;;
    down) pactl set-sink-volume @DEFAULT_SINK@ -5% ;;
    mute) pactl set-sink-mute @DEFAULT_SINK@ toggle ;;
    set) pactl set-sink-volume @DEFAULT_SINK@ "${2:-50}%" ;;
    get) pactl get-sink-volume @DEFAULT_SINK@ ;;
    sinks) pactl list short sinks ;;
    set-sink) pactl set-default-sink "$2" ;;
    *) echo "Usage: volume-ctl.sh [up|down|mute|set|get|sinks|set-sink]"; exit 1 ;;
esac