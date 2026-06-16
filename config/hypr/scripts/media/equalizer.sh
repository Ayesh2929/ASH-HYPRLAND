#!/bin/bash
set -euo pipefail

case "${1:-}" in
    list) pactl list modules | grep -A 5 "module-equalizer-sink" ;;
    load)
        pactl load-module module-equalizer-sink sink_name=equalized
        pactl set-default-sink equalized
        ;;
    unload) pactl unload-module module-equalizer-sink ;;
    *) echo "Usage: equalizer.sh [list|load|unload]"; exit 1 ;;
esac