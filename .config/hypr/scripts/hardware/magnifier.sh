#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — MAGNIFIER / ZOOM                             ║
# ║           Screen zoom in/out with OSD notification                        ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly STATE_FILE="${CACHE_DIR}/magnifier-state"
readonly LOG_FILE="${CACHE_DIR}/logs/magnifier.log"

readonly DEFAULT_ZOOM=1.0
readonly ZOOM_STEP=0.25
readonly MAX_ZOOM=5.0
readonly MIN_ZOOM=1.0

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 ZOOM MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

get_current_zoom() {
    if [[ -f "${STATE_FILE}" ]]; then
        cat "${STATE_FILE}" 2>/dev/null || echo "${DEFAULT_ZOOM}"
    else
        echo "${DEFAULT_ZOOM}"
    fi
}

save_zoom() {
    local zoom="$1"
    mkdir -p "${CACHE_DIR}"
    echo "${zoom}" > "${STATE_FILE}"
}

apply_zoom() {
    local zoom="$1"

    # Apply via Hyprland cursor_zoom_factor
    hyprctl keyword cursor:zoom_factor "${zoom}" 2>/dev/null || true

    # Save state
    save_zoom "${zoom}"

    # Show OSD
    local pct
    pct=$(awk "BEGIN{printf \"%.0f\", ${zoom} * 100}")

    if command -v swayosd-client &>/dev/null; then
        swayosd-client --custom-message "🔍 ${pct}%" 2>/dev/null || true
    else
        notify-send "🔍 Zoom: ${zoom}x" \
            "$(awk "BEGIN{printf \"%.0f%%\", ${zoom} * 100}")" \
            --app-name="ASH Magnifier" \
            --expire-time=1500 \
            --hint=string:synchronous:magnifier \
            2>/dev/null || true
    fi

    log "INFO" "Zoom: ${zoom}x"
}

zoom_in() {
    local current
    current=$(get_current_zoom)
    local new
    new=$(awk "BEGIN{
        z = ${current} + ${ZOOM_STEP};
        if (z > ${MAX_ZOOM}) z = ${MAX_ZOOM};
        printf \"%.2f\", z
    }")
    apply_zoom "${new}"
}

zoom_out() {
    local current
    current=$(get_current_zoom)
    local new
    new=$(awk "BEGIN{
        z = ${current} - ${ZOOM_STEP};
        if (z < ${MIN_ZOOM}) z = ${MIN_ZOOM};
        printf \"%.2f\", z
    }")
    apply_zoom "${new}"
}

zoom_reset() {
    apply_zoom "${DEFAULT_ZOOM}"
}

zoom_set() {
    local level="$1"
    # Clamp to valid range
    local zoom
    zoom=$(awk "BEGIN{
        z = ${level};
        if (z < ${MIN_ZOOM}) z = ${MIN_ZOOM};
        if (z > ${MAX_ZOOM}) z = ${MAX_ZOOM};
        printf \"%.2f\", z
    }")
    apply_zoom "${zoom}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-get}"
    local value="${2:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        zoom-in  | in)    zoom_in ;;
        zoom-out | out)   zoom_out ;;
        reset    | off)   zoom_reset ;;
        set)              zoom_set "${value:-${DEFAULT_ZOOM}}" ;;
        get)              get_current_zoom ;;
        status)
            local zoom
            zoom=$(get_current_zoom)
            local pct
            pct=$(awk "BEGIN{printf \"%.0f\", ${zoom} * 100}")
            echo "Zoom: ${zoom}x (${pct}%)"
            ;;
        *)
            echo "Usage: magnifier.sh [zoom-in|zoom-out|reset|set LEVEL|get|status]"
            exit 1
            ;;
    esac
}

main "$@"