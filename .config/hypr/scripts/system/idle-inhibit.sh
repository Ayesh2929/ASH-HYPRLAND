#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — IDLE INHIBITOR                               ║
# ║           Toggle system idle prevention with multiple backends             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/idle-inhibit.log"
readonly PID_FILE="/tmp/ash-idle-inhibitor.pid"
readonly STATE_FILE="${CACHE_DIR}/idle-inhibit-state"
readonly WAYBAR_SIGNAL=10

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

is_inhibited() {
    [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null
}

signal_waybar() {
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

enable_inhibit() {
    if is_inhibited; then
        warn "Already inhibited"
        return 0
    fi

    info "Enabling idle inhibitor..."

    local success=false

    # Method 1: systemd-inhibit (best)
    if command -v systemd-inhibit &>/dev/null; then
        systemd-inhibit \
            --what="idle:sleep:handle-lid-switch" \
            --who="ASH" \
            --why="User requested idle inhibition" \
            --mode="block" \
            /bin/sleep infinity &>/dev/null &
        echo $! > "${PID_FILE}"
        disown
        success=true
    fi

    # Method 2: Wayland idle inhibit protocol
    if [[ "${success}" == "false" ]] && command -v wayland-inhibit &>/dev/null; then
        wayland-inhibit sleep infinity &>/dev/null &
        echo $! > "${PID_FILE}"
        disown
        success=true
    fi

    # Method 3: Keep-awake workaround
    if [[ "${success}" == "false" ]]; then
        # Fake mouse movement every 30s to prevent idle
        (while true; do
            hyprctl dispatch movecursor 0 0 &>/dev/null
            sleep 30
        done) &>/dev/null &
        echo $! > "${PID_FILE}"
        disown
        success=true
    fi

    if [[ "${success}" == "true" ]]; then
        echo "enabled" > "${STATE_FILE}"
        signal_waybar
        notify-send "⚡ Idle Inhibited" \
            "System will not sleep automatically" \
            --app-name="ASH Idle" \
            --icon=system-shutdown \
            --expire-time=3000 \
            2>/dev/null || true
        ok "Idle inhibitor enabled"
        log "INFO" "Idle inhibitor enabled (PID: $(cat "${PID_FILE}" 2>/dev/null))"
    else
        warn "No idle inhibitor backend available"
    fi
}

disable_inhibit() {
    if ! is_inhibited; then
        warn "Not currently inhibited"
        return 0
    fi

    info "Disabling idle inhibitor..."

    local pid
    pid=$(cat "${PID_FILE}" 2>/dev/null || echo "")

    if [[ -n "${pid}" ]]; then
        kill "${pid}" 2>/dev/null || true
        pkill -P "${pid}" 2>/dev/null || true
    fi

    rm -f "${PID_FILE}"
    echo "disabled" > "${STATE_FILE}"
    signal_waybar

    notify-send "💤 Idle Allowed" \
        "System will sleep normally" \
        --app-name="ASH Idle" \
        --expire-time=2000 \
        2>/dev/null || true

    ok "Idle inhibitor disabled"
    log "INFO" "Idle inhibitor disabled"
}

toggle_inhibit() {
    if is_inhibited; then
        disable_inhibit
    else
        enable_inhibit
    fi
}

main() {
    local action="${1:-toggle}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        toggle)        toggle_inhibit ;;
        enable  | on)  enable_inhibit ;;
        disable | off) disable_inhibit ;;
        status)
            if is_inhibited; then
                echo "active (PID: $(cat "${PID_FILE}" 2>/dev/null))"
            else
                echo "inactive"
            fi
            ;;
        is-active)
            is_inhibited && echo "true" || echo "false"
            ;;
        *)
            echo "Usage: idle-inhibit.sh [toggle|enable|disable|status|is-active]"
            exit 1
            ;;
    esac
}

main "$@"