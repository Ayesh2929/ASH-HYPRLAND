#!/usr/bin/env bash
# ASH DOTFILES v5.0 OMEGA — swaync: start/stop a screen recording
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
PID_FILE="${STATE_DIR}/screenrecord.pid"
OUT_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$STATE_DIR" "$OUT_DIR" 2>/dev/null || true

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name="ASH" --urgency="${2:-low}" "$1" "${3:-}" 2>/dev/null || true
}

if [[ -f "$PID_FILE" ]] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
    notify "⏹  Recording stopped" low "$OUT_DIR"
    exit 0
fi

if command -v wf-recorder >/dev/null 2>&1; then
    out="${OUT_DIR}/rec-$(date '+%Y%m%d-%H%M%S').mp4"
    setsid wf-recorder -f "$out" >/dev/null 2>&1 &
    echo $! > "$PID_FILE"
    notify "⏺  Recording started" low "$(basename "$out")"
else
    notify "⚠ Screen recording unavailable" critical "Install wf-recorder"
    exit 1
fi
exit 0
