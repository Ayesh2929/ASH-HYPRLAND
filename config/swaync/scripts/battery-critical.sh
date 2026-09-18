#!/usr/bin/env bash
# ASH DOTFILES v5.0 OMEGA — swaync: critical-battery notification
set -euo pipefail
BAT="${1:-}"
if [[ -z "$BAT" ]]; then
    for b in /sys/class/power_supply/BAT*/; do [[ -d "$b" ]] && { BAT="$b"; break; }; done
fi
[[ -n "$BAT" && -d "$BAT" ]] || exit 0

capacity="$(cat "${BAT}capacity" 2>/dev/null || echo 0)"
status="$(cat "${BAT}status" 2>/dev/null || echo Unknown)"
[[ "$status" == "Discharging" ]] || exit 0
(( capacity <= 5 )) || exit 0

command -v notify-send >/dev/null 2>&1 && \
    notify-send --app-name="ASH" --urgency=critical --expire-time=0 \
        "🪫 Battery critical" "${capacity}% remaining — plug in now" 2>/dev/null || true
command -v hyprctl >/dev/null 2>&1 && hyprctl notify 5 8000 "rgb(ff5555)" "Battery critical: ${capacity}%" >/dev/null 2>&1 || true
exit 0
