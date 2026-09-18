#!/usr/bin/env bash
# ASH game-mode — enable: switch to performance profile
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
STATE_FILE="$STATE_DIR/game-mode.json"
mkdir -p "$STATE_DIR"
# Toggle compositor settings if hyprctl available
if command -v hyprctl &>/dev/null; then
    hyprctl keyword animations:enabled 0 2>/dev/null || true
    hyprctl keyword decoration:blur:enabled 0 2>/dev/null || true
    hyprctl keyword general:gaps_in 0 2>/dev/null || true
fi
# Power profile
if command -v powerprofilesctl &>/dev/null; then
    powerprofilesctl set performance 2>/dev/null || true
fi
printf '{"enabled":true,"ts":%s}\n' "$(date +%s)" > "$STATE_FILE"
echo "game-mode: enabled (performance)"
exit 0
