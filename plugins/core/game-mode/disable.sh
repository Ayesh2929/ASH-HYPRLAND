#!/usr/bin/env bash
# ASH game-mode — disable: restore balanced profile
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
STATE_FILE="$STATE_DIR/game-mode.json"
mkdir -p "$STATE_DIR"
if command -v hyprctl &>/dev/null; then
    hyprctl keyword animations:enabled 1 2>/dev/null || true
    hyprctl keyword decoration:blur:enabled 1 2>/dev/null || true
    hyprctl reload 2>/dev/null || true
fi
if command -v powerprofilesctl &>/dev/null; then
    powerprofilesctl set balanced 2>/dev/null || true
fi
printf '{"enabled":false,"ts":%s}\n' "$(date +%s)" > "$STATE_FILE"
echo "game-mode: disabled (balanced)"
exit 0
