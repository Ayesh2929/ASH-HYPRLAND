#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — SCREEN MAGNIFIER                             ║
# ║           Zoom in/out/reset with OSD notification                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/magnifier.log"
readonly ZOOM_STATE="${CACHE_DIR}/zoom-level"
readonly MIN_ZOOM=1.0
readonly MAX_ZOOM=5.0
readonly ZOOM_STEP=0.25

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 ZOOM CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

get_current_zoom() {
    if [[ -f "${ZOOM_STATE}" ]]; then
        cat "${ZOOM_STATE}"
    else
        echo "1.0"
    fi
}

set_zoom() {
    local zoom="$1"

    # Clamp zoom level
    zoom=$(awk "BEGIN{
        z = ${zoom}
        if (z < ${MIN_ZOOM}) z = ${MIN_ZOOM}
        if (z > ${MAX_ZOOM}) z = ${MAX_ZOOM}
        printf \"%.2f\", z
    }")

    # Apply via Hyprland cursor zoom
    hyprctl keyword cursor:zoom_factor "${zoom}" 2>/dev/null

    # Save state
    echo "${zoom}" > "${ZOOM_STATE}"

    # Show OSD
    local pct
    pct=$(awk "BEGIN{printf \"%.0f\", ${zoom} * 100}")

    if [[ "${zoom}" == "1.00" ]]; then
        notify-send "🔍 Zoom Reset" "100% — Normal view" \
            --app-name="ASH Magnifier" \
            --expire-time=1500 \
            2>/dev/null || true
    else
        # Build progress bar
        local bar_width=10
        local filled=$(awk "BEGIN{printf \"%.0f\", (${zoom}-1)/(${MAX_ZOOM}-1)*${bar_width}}")
        local bar=""
        for (( i=0; i<filled; i++ )); do bar+="█"; done
        for (( i=filled; i<bar_width; i++ )); do bar+="░"; done

        notify-send "🔍 Zoom: ${zoom}x" \
            "${bar}  ${pct}%" \
            --app-name="ASH Magnifier" \
            --expire-time=1200 \
            --hint=int:value:"${pct}" \
            --hint=string:synchronous:magnifier \
            2>/dev/null || true
    fi

    log "INFO" "Zoom set to ${zoom}x"
    echo "${zoom}"
}

zoom_in() {
    local current
    current=$(get_current_zoom)
    local new
    new=$(awk "BEGIN{printf \"%.2f\", ${current} + ${ZOOM_STEP}}")
    set_zoom "${new}"
}

zoom_out() {
    local current
    current=$(get_current_zoom)
    local new
    new=$(awk "BEGIN{printf \"%.2f\", ${current} - ${ZOOM_STEP}}")
    set_zoom "${new}"
}

zoom_reset() {
    set_zoom "1.0"
}

zoom_set() {
    local level="${1:-1.0}"
    set_zoom "${level}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"
    shift || true

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        zoom-in  | in  | "+") zoom_in ;;
        zoom-out | out | "-") zoom_out ;;
        reset    | "1")       zoom_reset ;;
        set)                  zoom_set "${1:-1.0}" ;;
        get | status)         get_current_zoom ;;
        *)
            echo "Usage: magnifier.sh [zoom-in|zoom-out|reset|set LEVEL|get]"
            exit 1
            ;;
    esac
}

main "$@"