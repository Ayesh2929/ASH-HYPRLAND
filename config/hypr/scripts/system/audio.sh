#!/bin/bash
set -euo pipefail

case "${1:-}" in
    sinks) pactl list short sinks ;;
    sources) pactl list short sources ;;
    default-sink) pactl get-default-sink ;;
    default-source) pactl get-default-source ;;
    set-sink) pactl set-default-sink "$2" ;;
    set-source) pactl set-default-source "$2" ;;
    *) echo "Usage: audio.sh [sinks|sources|default-sink|default-source|set-sink|set-source]"; exit 1 ;;
esac