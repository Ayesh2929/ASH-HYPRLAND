#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — battery monitor                                    ║
# ║  Referenced by config/hypr/autostart.conf as a daemon.                        ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# Usage: battery-monitor.sh [--daemon] [--once] [--interval N]
set -euo pipefail

INTERVAL=60
DAEMON=1
LOW=20
CRIT=10
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
LOG_FILE="${STATE_DIR}/battery-monitor.log"
FLAG_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-battery"
mkdir -p "$STATE_DIR" "$FLAG_DIR" 2>/dev/null || true

while (( $# )); do
    case "$1" in
        --help|-h) printf 'Usage: %s [--daemon|--once] [--interval N]\n' "${0##*/}"; exit 0 ;;
        --once)     DAEMON=0; shift ;;
        --daemon)   DAEMON=1; shift ;;
        --interval) INTERVAL="${2:-60}"; shift 2 ;;
        *)          shift ;;
    esac
done

battery_path() {
    local b
    for b in /sys/class/power_supply/BAT*/; do
        [[ -d "$b" ]] && { printf '%s' "$b"; return 0; }
    done
    return 1
}

notify() {
    command -v notify-send >/dev/null 2>&1 || return 0
    notify-send --app-name="ash-power" --urgency="${2:-normal}" "$1" "${3:-}" 2>/dev/null || true
}

check_once() {
    local bat capacity status
    bat="$(battery_path || true)"
    [[ -n "$bat" ]] || return 0
    capacity="$(cat "${bat}capacity" 2>/dev/null || echo 100)"
    status="$(cat "${bat}status" 2>/dev/null || echo Unknown)"
    [[ "$capacity" =~ ^[0-9]+$ ]] || capacity=100

    if [[ "$status" == "Discharging" ]]; then
        if (( capacity <= CRIT )) && [[ ! -f "${FLAG_DIR}/crit" ]]; then
            touch "${FLAG_DIR}/crit"
            notify "🪫 Battery critical" critical "${capacity}% — connect the charger now"
            command -v hyprctl >/dev/null 2>&1 && hyprctl notify 5 8000 "rgb(ff5555)" "Battery critical: ${capacity}%" >/dev/null 2>&1 || true
        elif (( capacity <= LOW )) && [[ ! -f "${FLAG_DIR}/low" ]]; then
            touch "${FLAG_DIR}/low"
            notify "🔋 Battery low" normal "${capacity}% remaining"
        fi
    else
        rm -f "${FLAG_DIR}/crit" "${FLAG_DIR}/low" 2>/dev/null || true
    fi
    printf '[%s] %s%% %s\n' "$(date '+%F %T')" "$capacity" "$status" >> "$LOG_FILE" 2>/dev/null || true
    return 0
}

if (( DAEMON == 0 )); then
    check_once
    exit 0
fi

trap 'exit 0' INT TERM
while :; do
    check_once || true
    sleep "$INTERVAL"
done
