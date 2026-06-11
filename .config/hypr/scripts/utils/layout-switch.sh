#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — LAYOUT SWITCH                                ║
# ║           Toggle between Dwindle and Master layouts with Rofi picker       ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LAYOUT_STATE="${CACHE_DIR}/current-layout"
readonly LOG_FILE="${CACHE_DIR}/logs/layout.log"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

get_current_layout() {
    if [[ -f "${LAYOUT_STATE}" ]]; then
        cat "${LAYOUT_STATE}" 2>/dev/null || echo "dwindle"
    else
        echo "dwindle"
    fi
}

set_layout() {
    local layout="$1"

    hyprctl keyword general:layout "${layout}" 2>/dev/null

    echo "${layout}" > "${LAYOUT_STATE}"

    notify-send "🗂️ Layout" \
        "Switched to: ${layout^}" \
        --app-name="ASH Layout" \
        --expire-time=2000 \
        2>/dev/null || true

    log "INFO" "Layout: ${layout}"
}

cycle_layout() {
    local current
    current=$(get_current_layout)

    local next
    case "${current}" in
        dwindle) next="master" ;;
        master)  next="dwindle" ;;
        *)       next="dwindle" ;;
    esac

    set_layout "${next}"
}

rofi_picker() {
    local current
    current=$(get_current_layout)

    local selected
    selected=$(printf \
        "🌿 Dwindle (BSP)%s\n👑 Master-Stack%s" \
        "$([[ "${current}" == "dwindle" ]] && echo " ✓" || echo "")" \
        "$([[ "${current}" == "master"  ]] && echo " ✓" || echo "")" \
        | rofi \
            -dmenu \
            -i \
            -p "🗂️ Tiling Layout" \
            -theme-str 'window { width: 380px; } listview { lines: 2; }' \
            2>/dev/null) || {
        log "INFO" "Layout picker cancelled"
        exit 0
    }

    case "${selected}" in
        "🌿 Dwindle"*) set_layout "dwindle" ;;
        "👑 Master"*)  set_layout "master" ;;
    esac
}

main() {
    local action="${1:-cycle}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        cycle | toggle)   cycle_layout ;;
        dwindle)          set_layout "dwindle" ;;
        master)           set_layout "master" ;;
        picker | rofi)    rofi_picker ;;
        get | current)    get_current_layout ;;
        *)
            echo "Usage: layout-switch.sh [cycle|dwindle|master|picker|get]"
            exit 1
            ;;
    esac
}

main "$@"