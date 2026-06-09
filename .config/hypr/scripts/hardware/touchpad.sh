#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — TOUCHPAD CONTROL                             ║
# ║           Enable/disable/toggle touchpad + auto-disable with mouse         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: touchpad.sh [ACTION]
#
# ACTIONS:
#   toggle   — Toggle touchpad on/off
#   enable   — Enable touchpad
#   disable  — Disable touchpad
#   status   — Show touchpad status
#   auto     — Auto-disable when mouse connected (daemon mode)
#   config   — Show current touchpad config

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/touchpad.log"
readonly STATE_FILE="${CACHE_DIR}/touchpad-state"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 TOUCHPAD DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

get_touchpad_name() {
    # Try hyprctl first
    local name
    name=$(hyprctl devices -j 2>/dev/null \
        | jq -r '.[] | select(.type == "touchpad") | .name' 2>/dev/null \
        | head -1)

    if [[ -n "${name}" ]]; then
        echo "${name}"
        return 0
    fi

    # Fallback: libinput
    name=$(libinput list-devices 2>/dev/null \
        | grep -A5 "Capabilities.*pointer" \
        | grep "Device:" \
        | grep -i "touchpad\|trackpad\|synaptics\|elan\|alps" \
        | head -1 \
        | sed 's/Device:\s*//')

    echo "${name:-}"
}

is_touchpad_enabled() {
    if [[ -f "${STATE_FILE}" ]]; then
        local state
        state=$(cat "${STATE_FILE}")
        [[ "${state}" == "enabled" ]]
    else
        # Default: enabled
        echo "enabled" > "${STATE_FILE}"
        return 0
    fi
}

is_mouse_connected() {
    # Check for external mouse (USB/Bluetooth, not touchpad)
    local devices
    devices=$(hyprctl devices -j 2>/dev/null \
        | jq -r '.[] | select(.type == "pointer" and (.name | contains("touchpad") | not)) | .name' \
        2>/dev/null)

    [[ -n "${devices}" ]]
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖱️ TOUCHPAD CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

enable_touchpad() {
    info "Enabling touchpad..."

    # hyprctl method
    hyprctl keyword device[synps/2 synaptics touchpad]:enabled true 2>/dev/null || true
    hyprctl keyword device[elan touchpad]:enabled true 2>/dev/null || true

    # Try by keyword
    local tp_name
    tp_name=$(get_touchpad_name)
    if [[ -n "${tp_name}" ]]; then
        hyprctl keyword "device[${tp_name}]:enabled" true 2>/dev/null || true
    fi

    # libinput via xinput fallback
    if command -v xinput &>/dev/null; then
        local id
        id=$(xinput list 2>/dev/null \
            | grep -i "touchpad\|trackpad" \
            | grep -oP 'id=\K\d+' \
            | head -1)
        [[ -n "${id}" ]] && xinput enable "${id}" 2>/dev/null || true
    fi

    echo "enabled" > "${STATE_FILE}"

    notify-send "🖱️ Touchpad Enabled" \
        "Touchpad is now active" \
        --app-name="ASH Input" \
        --expire-time=2000 \
        --icon=input-touchpad-symbolic \
        2>/dev/null || true

    ok "Touchpad enabled"
    log "INFO" "Touchpad enabled"
}

disable_touchpad() {
    info "Disabling touchpad..."

    # hyprctl method
    hyprctl keyword device[synps/2 synaptics touchpad]:enabled false 2>/dev/null || true
    hyprctl keyword device[elan touchpad]:enabled false 2>/dev/null || true

    local tp_name
    tp_name=$(get_touchpad_name)
    if [[ -n "${tp_name}" ]]; then
        hyprctl keyword "device[${tp_name}]:enabled" false 2>/dev/null || true
    fi

    # xinput fallback
    if command -v xinput &>/dev/null; then
        local id
        id=$(xinput list 2>/dev/null \
            | grep -i "touchpad\|trackpad" \
            | grep -oP 'id=\K\d+' \
            | head -1)
        [[ -n "${id}" ]] && xinput disable "${id}" 2>/dev/null || true
    fi

    echo "disabled" > "${STATE_FILE}"

    notify-send "🚫 Touchpad Disabled" \
        "Touchpad is now inactive" \
        --app-name="ASH Input" \
        --expire-time=2000 \
        --icon=input-touchpad-symbolic \
        2>/dev/null || true

    ok "Touchpad disabled"
    log "INFO" "Touchpad disabled"
}

toggle_touchpad() {
    if is_touchpad_enabled; then
        disable_touchpad
    else
        enable_touchpad
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🤖 AUTO-DISABLE DAEMON
# ═══════════════════════════════════════════════════════════════════════════════

auto_daemon() {
    info "Auto-disable touchpad daemon starting..."
    log "INFO" "Auto-disable daemon started"

    local last_mouse_state=""

    while true; do
        local current_state
        is_mouse_connected && current_state="mouse" || current_state="no-mouse"

        if [[ "${current_state}" != "${last_mouse_state}" ]]; then
            if [[ "${current_state}" == "mouse" ]]; then
                info "Mouse connected — disabling touchpad"
                disable_touchpad
            else
                info "Mouse disconnected — enabling touchpad"
                enable_touchpad
            fi
            last_mouse_state="${current_state}"
            log "INFO" "Auto-switch: ${current_state}"
        fi

        sleep 3
    done
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📊 STATUS
# ═══════════════════════════════════════════════════════════════════════════════

show_status() {
    local enabled
    is_touchpad_enabled && enabled="✅ Enabled" || enabled="❌ Disabled"

    local mouse
    is_mouse_connected && mouse="🖱️ Connected" || mouse="No external mouse"

    local tp_name
    tp_name=$(get_touchpad_name)

    echo ""
    echo "  🖱️ Touchpad Status"
    echo "  ─────────────────────────────"
    echo "  State:  ${enabled}"
    echo "  Device: ${tp_name:-Unknown}"
    echo "  Mouse:  ${mouse}"
    echo ""
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-toggle}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        toggle)    toggle_touchpad ;;
        enable)    enable_touchpad ;;
        disable)   disable_touchpad ;;
        status)    show_status ;;
        auto)      auto_daemon ;;
        config)
            hyprctl devices 2>/dev/null | grep -A5 -i touchpad || echo "No touchpad found"
            ;;
        *)
            echo "Usage: touchpad.sh [toggle|enable|disable|status|auto|config]"
            exit 1
            ;;
    esac
}

main "$@"