#!/usr/bin/env bash
# ASH DOTFILES v5.0 OMEGA — swaync: react to a theme change
# Referenced by config/swaync/config.json ("exec" of the theme-changed handler).
set -euo pipefail
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
LOG_FILE="${STATE_DIR}/swaync-theme-change.log"
mkdir -p "$STATE_DIR" 2>/dev/null || true

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*" >> "$LOG_FILE" 2>/dev/null || true; }

# The theme engine writes the active palette here; reload the stylesheet so the
# notification centre picks up the new colours without a restart.
THEME_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/ash/current-theme"
[[ -f "$THEME_FILE" ]] && log "theme -> $(head -n1 "$THEME_FILE" 2>/dev/null || true)" || log "theme changed"

command -v swaync-client >/dev/null 2>&1 && swaync-client --reload-css >/dev/null 2>&1 || true
exit 0
