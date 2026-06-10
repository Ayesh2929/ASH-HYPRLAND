#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — WAYBAR IDLE INHIBITOR MODULE                 ║
# ║           Toggle and display idle inhibitor state                          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly STATE_FILE="${CACHE_DIR}/idle-inhibitor-state"
readonly PID_FILE="/tmp/ash-idle-inhibitor.pid"

# ═══════════════════════════════════════════════════════════════════════════════
# 💤 IDLE INHIBITOR CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

is_inhibited() {
    [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null
}

enable_inhibitor() {
    if is_inhibited; then
        return 0
    fi

    # Use systemd-inhibit if available (most reliable)
    if command -v systemd-inhibit &>/dev/null; then
        systemd-inhibit \
            --what="idle:sleep:handle-lid-switch" \
            --who="ASH Idle Inhibitor" \
            --why="Manually inhibited by user" \
            --mode="block" \
            sleep infinity &>/dev/null &
        echo $! > "${PID_FILE}"
        disown
        echo "enabled" > "${STATE_FILE}"
        return 0
    fi

    # Fallback: use wayland-inhibit or caffeinate
    if command -v wayland-inhibit &>/dev/null; then
        wayland-inhibit sleep infinity &>/dev/null &
        echo $! > "${PID_FILE}"
        disown
    else
        # Simple sleep as placeholder
        sleep infinity &
        echo $! > "${PID_FILE}"
        disown
    fi

    echo "enabled" > "${STATE_FILE}"
}

disable_inhibitor() {
    if ! is_inhibited; then
        return 0
    fi

    local pid
    pid=$(cat "${PID_FILE}" 2>/dev/null || echo "")

    if [[ -n "${pid}" ]]; then
        kill "${pid}" 2>/dev/null || true
        # Also kill the sleep process
        pkill -P "${pid}" 2>/dev/null || true
    fi

    rm -f "${PID_FILE}"
    echo "disabled" > "${STATE_FILE}"
}

toggle_inhibitor() {
    if is_inhibited; then
        disable_inhibitor
        notify-send "💤 Idle" "Idle inhibitor disabled — screen will sleep normally" \
            --app-name="ASH Idle" --expire-time=2000 2>/dev/null || true
    else
        enable_inhibitor
        notify-send "⚡ Idle Inhibited" "Screen and sleep prevented" \
            --app-name="ASH Idle" --expire-time=2000 2>/dev/null || true
    fi

    # Signal Waybar to update
    pkill -SIGRTMIN+10 waybar 2>/dev/null || true
}

status_json() {
    if is_inhibited; then
        printf '{"text": "⚡", "class": "active", "tooltip": "Idle inhibited — click to allow sleep"}\n'
    else
        printf '{"text": "💤", "class": "inactive", "tooltip": "Idle allowed — click to inhibit"}\n'
    fi
}

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}"

    case "${action}" in
        status)
            status_json
            ;;
        toggle)
            toggle_inhibitor
            ;;
        enable | on)
            enable_inhibitor
            notify-send "⚡ Idle Inhibited" "Sleep prevented" --app-name="ASH Idle" --expire-time=2000 2>/dev/null || true
            pkill -SIGRTMIN+10 waybar 2>/dev/null || true
            ;;
        disable | off)
            disable_inhibitor
            notify-send "💤 Idle Allowed" "Sleep re-enabled" --app-name="ASH Idle" --expire-time=2000 2>/dev/null || true
            pkill -SIGRTMIN+10 waybar 2>/dev/null || true
            ;;
        is-active)
            is_inhibited && echo "true" || echo "false"
            ;;
        *)
            echo "Usage: idle-inhibitor.sh [status|toggle|enable|disable|is-active]"
            exit 1
            ;;
    esac
}

main "$@"