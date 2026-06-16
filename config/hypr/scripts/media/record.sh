#!/bin/bash
set -euo pipefail

SAVE_DIR="${HOME}/Videos/recordings"
mkdir -p "$SAVE_DIR"

case "${1:-}" in
    start)
        wf-recorder -f "$SAVE_DIR/$(date +%s).mp4" &
        echo $! > /tmp/wf-recorder.pid
        echo "Recording started"
        ;;
    stop)
        [[ -f /tmp/wf-recorder.pid ]] && kill "$(cat /tmp/wf-recorder.pid)" && rm /tmp/wf-recorder.pid
        echo "Recording stopped"
        ;;
    region)
        wf-recorder -g "$(slurp)" -f "$SAVE_DIR/$(date +%s).mp4" &
        echo $! > /tmp/wf-recorder.pid
        echo "Region recording started"
        ;;
    *) echo "Usage: record.sh [start|stop|region]"; exit 1 ;;
esac