#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — IDLE INHIBITOR                               ║
# ║           Toggle/manage system idle prevention                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly STATE_FILE="${CACHE_DIR}/idle-inhibitor-state"
readonly PID_FILE="/tmp/ash-idle-inhibit.pid"
readonly LOG_FILE="${CACHE_DIR}/logs/idle-inhibit.log"
readonly WAYBAR_SIGNAL=16

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }

# ═══════════════════════════════════════════════════════════════════════════════
# ⚙️ INHIBITOR MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

is_inhibiting() {
    if [[ -f "${PID_FILE}" ]]; then
        local pid
        pid=$(cat "${PID_FILE}" 2>/dev/null || echo "0")
        kill -0 "${pid}" 2>/dev/null
    else
        return 1
    fi
}

get_state() {
    if [[ -f "${STATE_FILE}" ]]; then
        cat "${STATE_FILE}" 2>/dev/null || echo "inactive"
    else
        echo "inactive"
    fi
}

start_inhibitor() {
    local reason="${1:-Manual}"

    if is_inhibiting; then
        info "Inhibitor already active"
        return 0
    fi

    # Try systemd-inhibit first (most reliable)
    if command -v systemd-inhibit &>/dev/null; then
        systemd-inhibit \
            --what=idle:sleep \
            --who="ASH Dotfiles" \
            --why="${reason}" \
            --mode=block \
            sleep infinity &>/dev/null &
        local pid=$!
        echo "${pid}" > "${PID_FILE}"
        echo "active:systemd:${reason}" > "${STATE_FILE}"
        ok "Inhibitor started (systemd): ${pid}"
        log "INFO" "Inhibitor start (systemd): ${reason} PID=${pid}"
    # Fallback: wayland-inhibit (hypothetical)
    elif command -v wayland-inhibit &>/dev/null; then
        wayland-inhibit --idle &>/dev/null &
        echo $! > "${PID_FILE}"
        echo "active:wayland:${reason}" > "${STATE_FILE}"
        ok "Inhibitor started (wayland)"
    else
        # Fallback: touch a file that hypridle can watch
        touch "${CACHE_DIR}/inhibit-active"
        echo "active:file:${reason}" > "${STATE_FILE}"
        ok "Inhibitor active (file-based)"
        log "INFO" "Inhibitor (file-based): ${reason}"
    fi

    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true

    notify-send "☕ Idle Inhibited" \
        "System will stay awake\nReason: ${reason}" \
        --app-name="ASH Idle" \
        --expire-time=3000 \
        2>/dev/null || true
}

stop_inhibitor() {
    if ! is_inhibiting && [[ "$(get_state)" != *"active"* ]]; then
        info "No inhibitor active"
        return 0
    fi

    # Kill inhibitor process
    if [[ -f "${PID_FILE}" ]]; then
        local pid
        pid=$(cat "${PID_FILE}" 2>/dev/null || echo "0")
        kill "${pid}" 2>/dev/null || true
        rm -f "${PID_FILE}"
    fi

    # Remove file-based inhibitor
    rm -f "${CACHE_DIR}/inhibit-active" 2>/dev/null || true

    echo "inactive" > "${STATE_FILE}"

    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true

    notify-send "💤 Idle Allowed" \
        "System can now sleep normally" \
        --app-name="ASH Idle" \
        --expire-time=2000 \
        2>/dev/null || true

    ok "Inhibitor stopped"
    log "INFO" "Inhibitor stopped"
}

toggle_inhibitor() {
    if is_inhibiting || [[ "$(get_state)" == *"active"* ]]; then
        stop_inhibitor
    else
        start_inhibitor "Toggle"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 STATUS
# ═══════════════════════════════════════════════════════════════════════════════

show_status() {
    local state
    state=$(get_state)

    if [[ "${state}" == *"active"* ]]; then
        local method reason
        method=$(echo "${state}" | cut -d: -f2)
        reason=$(echo "${state}" | cut -d: -f3-)
        echo "Status: ACTIVE (${method})"
        echo "Reason: ${reason}"
        is_inhibiting && echo "PID: $(cat "${PID_FILE}" 2>/dev/null)"
    else
        echo "Status: inactive"
    fi
}

waybar_status() {
    local state
    state=$(get_state)

    if [[ "${state}" == *"active"* ]]; then
        printf '{"text": "☕", "tooltip": "Idle inhibitor: ACTIVE\\nSystem stays awake", "class": "active"}\n'
    else
        printf '{"text": "󰒲", "tooltip": "Idle inhibitor: inactive\\nSystem sleeps normally", "class": "inactive"}\n'
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-toggle}"
    local value="${2:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        toggle)   toggle_inhibitor ;;
        start)    start_inhibitor "${value:-Manual}" ;;
        stop)     stop_inhibitor ;;
        status)   show_status ;;
        waybar)   waybar_status ;;
        is-active)
            is_inhibiting && echo "true" || echo "false"
            ;;
        *)
            echo "Usage: idle-inhibit.sh [toggle|start|stop|status|waybar|is-active]"
            exit 1
            ;;
    esac
}

main "$@"