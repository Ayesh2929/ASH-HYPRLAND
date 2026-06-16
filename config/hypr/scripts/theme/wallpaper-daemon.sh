#!/bin/bash
set -euo pipefail

DAEMON_PID="/tmp/wallpaper-daemon.pid"

start_daemon() {
    [[ -f "$DAEMON_PID" ]] && kill "$(cat "$DAEMON_PID")" 2>/dev/null || true
    
    (
        echo $$ > "$DAEMON_PID"
        while true; do
            ~/.config/hypr/scripts/theme/smart-wallpaper.sh apply
            sleep 300
        done
    ) &
    disown
    echo "Wallpaper daemon started"
}

stop_daemon() {
    [[ -f "$DAEMON_PID" ]] && kill "$(cat "$DAEMON_PID")" 2>/dev/null && rm "$DAEMON_PID"
    echo "Wallpaper daemon stopped"
}

status_daemon() {
    [[ -f "$DAEMON_PID" ]] && kill -0 "$(cat "$DAEMON_PID")" 2>/dev/null && echo "Running" || echo "Stopped"
}

main() {
    case "${1:-}" in
        start) start_daemon ;;
        stop) stop_daemon ;;
        status) status_daemon ;;
        *) echo "Usage: wallpaper-daemon.sh [start|stop|status]"; exit 1 ;;
    esac
}

main "$@"