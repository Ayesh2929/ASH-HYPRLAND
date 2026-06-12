#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI MAN PAGE VIEWER                         ║
# ║           Search and view man pages with syntax highlighting               ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

main() {
    mkdir -p "${CACHE_DIR}/logs"
    log "INFO" "Man page viewer opened"

    # Get all available man pages
    local selected
    selected=$(man -k . 2>/dev/null \
        | awk '{print $1"("$2")  "$3,$4,$5,$6,$7}' \
        | sort -u \
        | rofi \
            -dmenu \
            -i \
            -p "📖 Man Pages" \
            -theme-str '
                window { width: 750px; }
                listview { columns: 1; lines: 16; }
                element { padding: 6px 12px; font-size: 12px;
                          font-family: "JetBrainsMono Nerd Font"; }
            ' \
            2>/dev/null) || {
        log "INFO" "Man page viewer cancelled"
        exit 0
    }

    # Extract command name and section
    local cmd section
    cmd=$(echo "${selected}" | awk '{print $1}' | cut -d'(' -f1)
    section=$(echo "${selected}" | awk '{print $1}' | grep -oP '\(\K[^)]+' || echo "")

    if [[ -z "${cmd}" ]]; then
        exit 0
    fi

    log "INFO" "Opening man page: ${cmd}(${section})"

    # Open man page with best available viewer
    if command -v nvim &>/dev/null; then
        # Neovim with man plugin
        if [[ -n "${section}" ]]; then
            kitty --title "man ${cmd}(${section})" \
                -e nvim -c "Man ${section} ${cmd}" -c "only" \
                2>/dev/null &
        else
            kitty --title "man ${cmd}" \
                -e nvim -c "Man ${cmd}" -c "only" \
                2>/dev/null &
        fi
    elif command -v bat &>/dev/null; then
        # bat with man syntax highlighting
        if [[ -n "${section}" ]]; then
            kitty --title "man ${cmd}" \
                -e bash -c "man ${section} ${cmd} | bat --language=man --style=plain --paging=always" \
                2>/dev/null &
        else
            kitty --title "man ${cmd}" \
                -e bash -c "man ${cmd} | bat --language=man --style=plain --paging=always" \
                2>/dev/null &
        fi
    else
        # Standard man
        if [[ -n "${section}" ]]; then
            kitty --title "man ${cmd}" -e man "${section}" "${cmd}" 2>/dev/null &
        else
            kitty --title "man ${cmd}" -e man "${cmd}" 2>/dev/null &
        fi
    fi

    disown
}

main "$@"