#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — dunst: notification action handler                ║
# ║  Referenced by every rule in ~/.config/dunst/rules/*.conf as:                ║
# ║      script = ~/.config/dunst/scripts/open-action.sh                         ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# dunst exports the notification context while running rule scripts:
#   DUNST_APP_NAME, DUNST_SUMMARY, DUNST_BODY, DUNST_URGENCY, DUNST_ID, …
# The first argument (when present) is the action to trigger.

set -euo pipefail

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
LOG_FILE="${STATE_DIR}/dunst-actions.log"
mkdir -p "$STATE_DIR" 2>/dev/null || true

action="${1:-}"
app="${DUNST_APP_NAME:-}"
case "$action" in
    ""|left-click)
        # Plain click: try to raise the window that sent the notification,
        # otherwise fall back to the first declared action.
        if command -v hyprctl >/dev/null 2>&1 && [[ -n "$app" ]]; then
            class_lc="$(printf '%s' "$app" | tr '[:upper:]' '[:lower:]')"
            if hyprctl dispatch focuswindow "class:${class_lc}" >/dev/null 2>&1; then
                printf '[%s] focus %s\n' "$(date '+%F %T')" "$app" >> "$LOG_FILE" 2>/dev/null || true
                exit 0
            fi
        fi
        command -v dunstctl >/dev/null 2>&1 && dunstctl action >/dev/null 2>&1 || true
        ;;
    dismiss|close)
        command -v dunstctl >/dev/null 2>&1 && dunstctl close >/dev/null 2>&1 || true
        ;;
    history)
        command -v dunstctl >/dev/null 2>&1 && dunstctl history-pop >/dev/null 2>&1 || true
        ;;
    *)
        # Named action — hand it back to dunst, or open it as a URI.
        if command -v dunstctl >/dev/null 2>&1 && dunstctl action "$action" >/dev/null 2>&1; then
            :
        elif command -v xdg-open >/dev/null 2>&1; then
            xdg-open "$action" >/dev/null 2>&1 || true
        fi
        ;;
esac

printf '[%s] action=%s app=%s\n' "$(date '+%F %T')" "${action:-default}" "${app:-unknown}" >> "$LOG_FILE" 2>/dev/null || true
exit 0
