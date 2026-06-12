#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — TOUCHPAD CONTROL (FULL)                      ║
# ║           Enable/disable/toggle with auto-disable on mouse connect         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly STATE_FILE="${CACHE_DIR}/touchpad-state"
readonly LOG_FILE="${CACHE_DIR}/logs/touchpad.log"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 TOUCHPAD DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

find_touchpad_device() {
    # Try Hyprland device list first
    local hypr_tp
    hypr_tp=$(hyprctl devices -j 2>/dev/null \
        | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for section_name, devices in data.items():
        if isinstance(devices, list):
            for d in devices:
                if isinstance(d, dict) and 'touchpad' in d.get('type', '').lower():
                    print(d.get('name', ''))
                    break
except:
    pass
" 2>/dev/null | head -1)

    if [[ -n "${hypr_tp}" ]]; then
        echo "${hypr_tp}"
        return 0
    fi

    # Fallback: search /sys for touchpad
    local sysfs_tp
    sysfs_tp=$(find /sys/class/input -name "mouse*" 2>/dev/null \
        | xargs -I{} cat {}/device/name 2>/dev/null \
        | grep -i "touchpad\|trackpad\|synaptics\|elan\|alps" \
        | head -1)

    echo "${sysfs_tp:-}"
}

is_touchpad_enabled() {
    if [[ -f "${STATE_FILE}" ]]; then
        [[ "$(cat "${STATE_FILE}" 2>/dev/null)" == "enabled" ]]
    else
        return 0  # Default: enabled
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖱️ TOUCHPAD CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

set_touchpad() {
    local state="$1"  # enabled or disabled
    local bool_val
    [[ "${state}" == "enabled" ]] && bool_val="true" || bool_val="false"

    # Try multiple methods for maximum compatibility
    local success=false

    # Method 1: Hyprland keyword (most reliable)
    # Try common touchpad device names
    local tp_names=(
        "synps/2 synaptics touchpad"
        "elan touchpad"
        "alps ps/2 alps dm touchpad"
        "elantech touchpad"
        "microsoft precision touchpad"
    )

    for tp_name in "${tp_names[@]}"; do
        if hyprctl keyword "device[${tp_name}]:enabled" "${bool_val}" 2>/dev/null; then
            success=true
        fi
    done

    # Method 2: libinput via xinput (X11 fallback)
    if command -v xinput &>/dev/null; then
        local tp_id
        tp_id=$(xinput list 2>/dev/null \
            | grep -i "touchpad\|trackpad" \
            | grep -oP 'id=\K\d+' \
            | head -1)

        if [[ -n "${tp_id}" ]]; then
            if [[ "${state}" == "enabled" ]]; then
                xinput enable "${tp_id}" 2>/dev/null && success=true
            else
                xinput disable "${tp_id}" 2>/dev/null && success=true
            fi
        fi
    fi

    # Save state
    echo "${state}" > "${STATE_FILE}"

    local msg
    [[ "${state}" == "enabled" ]] && msg="Touchpad enabled" || msg="Touchpad disabled"
    local icon
    [[ "${state}" == "enabled" ]] && icon="🖱️" || icon="🚫"

    notify-send "${icon} Input" \
        "${msg}" \
        --app-name="ASH Input" \
        --expire-time=2000 \
        2>/dev/null || true

    log "INFO" "Touchpad ${state}"
    [[ "${success}" == "true" ]] && ok "${msg}" || warn "Partial: ${msg} (some methods failed)"
}

toggle_touchpad() {
    if is_touchpad_enabled; then
        set_touchpad "disabled"
    else
        set_touchpad "enabled"
    fi
}

# Auto-disable when external mouse is connected
auto_daemon() {
    info "Touchpad auto-disable daemon starting..."
    log "INFO" "Auto-disable daemon started"

    local last_mouse_state=""

    while true; do
        # Check for external USB/Bluetooth mice (not touchpads)
        local mouse_count
        mouse_count=$(hyprctl devices -j 2>/dev/null \
            | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    count = 0
    for section, devices in data.items():
        if isinstance(devices, list):
            for d in devices:
                if isinstance(d, dict):
                    name = d.get('name', '').lower()
                    dtype = d.get('type', '').lower()
                    if 'pointer' in dtype and 'touchpad' not in name and 'trackpad' not in name:
                        count += 1
    print(count)
except:
    print(0)
" 2>/dev/null || echo "0")

        local current_state
        (( mouse_count > 0 )) && current_state="mouse" || current_state="no-mouse"

        if [[ "${current_state}" != "${last_mouse_state}" ]]; then
            if [[ "${current_state}" == "mouse" ]]; then
                info "External mouse detected — disabling touchpad"
                set_touchpad "disabled"
            else
                info "External mouse removed — enabling touchpad"
                set_touchpad "enabled"
            fi
            last_mouse_state="${current_state}"
        fi

        sleep 3
    done
}

show_status() {
    local tp_name
    tp_name=$(find_touchpad_device)
    local state
    is_touchpad_enabled && state="✅ Enabled" || state="❌ Disabled"

    echo ""
    echo "  🖱️ Touchpad Status"
    echo "  ─────────────────────────────"
    echo "  State:  ${state}"
    echo "  Device: ${tp_name:-Unknown}"
    echo ""
}

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        toggle | t)     toggle_touchpad ;;
        enable | on)    set_touchpad "enabled" ;;
        disable | off)  set_touchpad "disabled" ;;
        auto)           auto_daemon ;;
        status)         show_status ;;
        find)           find_touchpad_device ;;
        *)
            echo "Usage: touchpad.sh [toggle|enable|disable|auto|status|find]"
            exit 1
            ;;
    esac
}

main "$@"