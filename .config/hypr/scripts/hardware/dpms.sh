#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — DPMS / DISPLAY POWER MANAGEMENT              ║
# ║           Control display power, night light, and screen shaders          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly STATE_FILE="${CACHE_DIR}/dpms-state"
readonly NIGHT_STATE="${CACHE_DIR}/night-light-state"
readonly SHADER_STATE="${CACHE_DIR}/shader-state"
readonly LOG_FILE="${CACHE_DIR}/logs/dpms.log"

# Night light settings
readonly NIGHT_TEMP=4000       # Color temperature (Kelvin)
readonly NIGHT_BRIGHTNESS=0.85 # Brightness multiplier

# Shader paths
readonly SHADER_DIR="${HOME}/.config/hypr/assets/shaders"
readonly SHADERS=(
    ""                                           # Off
    "${SHADER_DIR}/blue-light-filter.glsl"      # Blue light filter
    "${SHADER_DIR}/vibrance.glsl"               # Vibrance boost
    "${SHADER_DIR}/crt.glsl"                    # CRT effect
)
readonly SHADER_NAMES=("Off" "Blue Light" "Vibrance" "CRT")

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ DISPLAY POWER
# ═══════════════════════════════════════════════════════════════════════════════

dpms_on() {
    hyprctl dispatch dpms on 2>/dev/null
    echo "on" > "${STATE_FILE}"
    log "INFO" "DPMS: on"
    ok "Displays enabled"
}

dpms_off() {
    hyprctl dispatch dpms off 2>/dev/null
    echo "off" > "${STATE_FILE}"
    log "INFO" "DPMS: off"
    info "Displays disabled"
}

dpms_toggle() {
    local state="on"
    [[ -f "${STATE_FILE}" ]] && state=$(cat "${STATE_FILE}" 2>/dev/null || echo "on")

    if [[ "${state}" == "on" ]]; then
        dpms_off
    else
        dpms_on
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌙 NIGHT LIGHT
# ═══════════════════════════════════════════════════════════════════════════════

night_enable() {
    local temp="${1:-${NIGHT_TEMP}}"

    echo "active:${temp}" > "${NIGHT_STATE}"

    # Try multiple backends
    if command -v wlsunset &>/dev/null; then
        pkill -x wlsunset 2>/dev/null || true
        wlsunset -T "${temp}" -t "${temp}" &>/dev/null &
        disown
        log "INFO" "Night light (wlsunset): ${temp}K"
    elif command -v gammastep &>/dev/null; then
        pkill -x gammastep 2>/dev/null || true
        gammastep -O "${temp}" &>/dev/null &
        disown
        log "INFO" "Night light (gammastep): ${temp}K"
    else
        # Fallback: Hyprland vibrancy/brightness via shader
        hyprctl keyword decoration:screen_shader "${SHADER_DIR}/blue-light-filter.glsl" 2>/dev/null || true
        log "INFO" "Night light (shader fallback)"
    fi

    notify-send "🌙 Night Light" \
        "Enabled — ${temp}K color temperature" \
        --app-name="ASH DPMS" \
        --expire-time=2000 \
        2>/dev/null || true
}

night_disable() {
    echo "inactive" > "${NIGHT_STATE}"

    pkill -x wlsunset  2>/dev/null || true
    pkill -x gammastep 2>/dev/null || true

    # Clear shader if it was the night light shader
    local current_shader
    current_shader=$(hyprctl getoption decoration:screen_shader 2>/dev/null \
        | grep -oP '(?<=str: ).*' | head -1 || echo "")

    if echo "${current_shader}" | grep -q "blue-light"; then
        hyprctl keyword decoration:screen_shader "" 2>/dev/null || true
    fi

    notify-send "☀️ Night Light Disabled" \
        "Normal color temperature restored" \
        --app-name="ASH DPMS" \
        --expire-time=2000 \
        2>/dev/null || true

    log "INFO" "Night light disabled"
}

night_toggle() {
    local state="inactive"
    if [[ -f "${NIGHT_STATE}" ]]; then
        state=$(cat "${NIGHT_STATE}" 2>/dev/null | cut -d: -f1 || echo "inactive")
    fi

    if [[ "${state}" == "active" ]]; then
        night_disable
    else
        night_enable
    fi
}

night_warmer() {
    local current_temp="${NIGHT_TEMP}"
    if [[ -f "${NIGHT_STATE}" ]]; then
        local saved
        saved=$(cat "${NIGHT_STATE}" 2>/dev/null | cut -d: -f2)
        [[ "${saved}" =~ ^[0-9]+$ ]] && current_temp="${saved}"
    fi
    local new_temp=$(( current_temp - 200 ))
    (( new_temp < 2000 )) && new_temp=2000
    night_enable "${new_temp}"
}

night_cooler() {
    local current_temp="${NIGHT_TEMP}"
    if [[ -f "${NIGHT_STATE}" ]]; then
        local saved
        saved=$(cat "${NIGHT_STATE}" 2>/dev/null | cut -d: -f2)
        [[ "${saved}" =~ ^[0-9]+$ ]] && current_temp="${saved}"
    fi
    local new_temp=$(( current_temp + 200 ))
    (( new_temp > 6500 )) && new_temp=6500
    night_enable "${new_temp}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎨 SHADER CYCLING
# ═══════════════════════════════════════════════════════════════════════════════

shader_cycle() {
    local current_idx=0
    if [[ -f "${SHADER_STATE}" ]]; then
        current_idx=$(cat "${SHADER_STATE}" 2>/dev/null || echo "0")
    fi

    local next_idx=$(( (current_idx + 1) % ${#SHADERS[@]} ))

    local shader="${SHADERS[${next_idx}]}"
    local name="${SHADER_NAMES[${next_idx}]}"

    if [[ -n "${shader}" ]] && [[ -f "${shader}" ]]; then
        hyprctl keyword decoration:screen_shader "${shader}" 2>/dev/null || true
    else
        hyprctl keyword decoration:screen_shader "" 2>/dev/null || true
    fi

    echo "${next_idx}" > "${SHADER_STATE}"

    notify-send "🎨 Screen Shader" \
        "${name}" \
        --app-name="ASH DPMS" \
        --expire-time=2000 \
        2>/dev/null || true

    log "INFO" "Shader: ${name}"
}

shader_set() {
    local shader_path="${1:-}"
    if [[ -n "${shader_path}" ]] && [[ -f "${shader_path}" ]]; then
        hyprctl keyword decoration:screen_shader "${shader_path}" 2>/dev/null || true
        log "INFO" "Shader set: ${shader_path}"
    else
        hyprctl keyword decoration:screen_shader "" 2>/dev/null || true
        log "INFO" "Shader cleared"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

main() {
    local action="${1:-status}"
    local value="${2:-}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        # DPMS
        on)             dpms_on ;;
        off)            dpms_off ;;
        toggle-dpms)    dpms_toggle ;;

        # Night light
        night-enable)   night_enable "${value}" ;;
        night-disable)  night_disable ;;
        night-toggle)   night_toggle ;;
        night-warmer)   night_warmer ;;
        night-cooler)   night_cooler ;;

        # Shaders
        shader-cycle)   shader_cycle ;;
        shader-set)     shader_set "${value}" ;;
        shader-off)     shader_set "" ;;

        # Status
        status)
            local dpms_state="on"
            [[ -f "${STATE_FILE}" ]] && dpms_state=$(cat "${STATE_FILE}" || echo "on")
            local night_state="inactive"
            [[ -f "${NIGHT_STATE}" ]] && night_state=$(cat "${NIGHT_STATE}" | cut -d: -f1 || echo "inactive")
            echo "DPMS: ${dpms_state} | Night light: ${night_state}"
            ;;

        *)
            echo "Usage: dpms.sh [on|off|toggle-dpms|night-enable|night-disable|night-toggle|night-warmer|shader-cycle|status]"
            exit 1
            ;;
    esac
}

main "$@"