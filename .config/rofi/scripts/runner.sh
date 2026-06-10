#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — ROFI COMMAND RUNNER                          ║
# ║           Run commands with history and shell integration                  ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly RUN_HISTORY="${CACHE_DIR}/run-history.txt"
readonly LOG_FILE="${CACHE_DIR}/logs/rofi.log"
readonly MAX_HISTORY=100

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

save_history() {
    local cmd="$1"
    mkdir -p "${CACHE_DIR}"

    # Remove duplicate
    if [[ -f "${RUN_HISTORY}" ]]; then
        grep -vFx "${cmd}" "${RUN_HISTORY}" > "${RUN_HISTORY}.tmp" 2>/dev/null || true
        mv "${RUN_HISTORY}.tmp" "${RUN_HISTORY}" 2>/dev/null || true
    fi

    # Prepend
    echo "${cmd}" | cat - "${RUN_HISTORY}" 2>/dev/null > "${RUN_HISTORY}.tmp" \
        || echo "${cmd}" > "${RUN_HISTORY}.tmp"
    mv "${RUN_HISTORY}.tmp" "${RUN_HISTORY}"

    # Limit
    head -"${MAX_HISTORY}" "${RUN_HISTORY}" > "${RUN_HISTORY}.tmp" 2>/dev/null
    mv "${RUN_HISTORY}.tmp" "${RUN_HISTORY}" 2>/dev/null || true
}

main() {
    mkdir -p "${CACHE_DIR}/logs"

    # Build history for display
    local history_items=""
    [[ -f "${RUN_HISTORY}" ]] && history_items=$(cat "${RUN_HISTORY}")

    # Show runner
    local cmd
    cmd=$(echo "${history_items}" | rofi \
        -dmenu \
        -i \
        -p "  Run" \
        -theme-str '
            window { width: 650px; }
            listview { lines: 12; }
        ' \
        2>/dev/null) || {
        log "INFO" "Runner cancelled"
        exit 0
    }

    if [[ -z "${cmd}" ]]; then
        exit 0
    fi

    save_history "${cmd}"
    log "INFO" "Run: ${cmd}"

    # Execute in background with fish
    fish -c "${cmd}" &>/dev/null & disown
}

main "$@"