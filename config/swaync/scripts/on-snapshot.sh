#!/usr/bin/env bash
# ASH DOTFILES v5.0 OMEGA — swaync: react to a config snapshot
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
LOG_FILE="${STATE_DIR}/swaync-snapshot.log"
mkdir -p "$STATE_DIR" 2>/dev/null || true
printf '[%s] snapshot hook: %s\n' "$(date '+%F %T')" "${1:-created}" >> "$LOG_FILE" 2>/dev/null || true

# Keep the newest snapshots visible in the notification centre.
snap_dir="${XDG_STATE_HOME:-$HOME/.local/state}/ash/snapshots"
if [[ -d "$snap_dir" ]]; then
    newest="$(find "$snap_dir" -maxdepth 1 -name '*.tar.gz' -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"
    [[ -n "$newest" ]] && command -v notify-send >/dev/null 2>&1 && \
        notify-send --app-name="ASH" --urgency=low "📸 Snapshot created" "$(basename "$newest")" 2>/dev/null || true
fi
exit 0
