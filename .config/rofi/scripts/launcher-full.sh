#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI FULL MULTI-MODE LAUNCHER               ║
# ║           All-in-one launcher: apps + run + ssh + windows + more          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly ROFI_THEME="${HOME}/.config/rofi/themes/ash-dynamic.rasi"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

main() {
    mkdir -p "${CACHE_DIR}/logs"
    log "INFO" "Full launcher opened"

    # Full multi-mode launcher
    rofi \
        -show drun \
        -modes "drun,run,window,ssh,emoji" \
        -theme "${ROFI_THEME}" \
        -theme-str '
            window { width: 750px; }
            listview { columns: 2; lines: 8; }
            element { padding: 8px 12px; }
            element-icon { size: 22px; }
        ' \
        -show-icons \
        -icon-theme "Papirus-Dark" \
        -display-drun "  Apps" \
        -display-run "  Run" \
        -display-window "🪟  Windows" \
        -display-ssh "  SSH" \
        -display-emoji "  Emoji" \
        -drun-display-format "{name}" \
        -drun-match-fields "name,generic,comment,categories,exec" \
        -matching fuzzy \
        -sort \
        -sorting-method fzf \
        -kb-cancel "Escape,Super_L" \
        2>/dev/null

    log "INFO" "Full launcher closed"
}

main "$@"