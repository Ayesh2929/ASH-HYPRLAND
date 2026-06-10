#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — DPMS & DISPLAY POWER MANAGEMENT              ║
# ║           Night light, screen shader, DPMS control                         ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/dpms.log"
readonly NIGHT_STATE="${CACHE_DIR}/night-mode-state"
readonly SHADER_STATE="${CACHE_DIR}/shader-state"
readonly SHADERS_DIR="${HOME}/.config/hypr/assets/shaders"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🌙 NIGHT LIGHT
# ═══════════════════════════════════════════════════════════════════════════════

get_night_state() {
    [[ -f "${NIGHT_STATE}" ]] && cat "${NIGHT_STATE}" || echo "off"
}

night_enable() {
    local temp="${1:-4000}"
    log "INFO" "Enabling night light at ${temp}K"

    # Try wlsunset
    if command -v wlsunset &>/dev/null; then
        pkill wlsunset 2>/dev/null || true
        sleep 0.2
        wlsunset -T "${temp}" -t "${temp}" &>/dev/null &
        disown
        echo "wlsunset:${temp}" > "${NIGHT_STATE}"
        ok "Night light enabled via wlsunset (${temp}K)"
        return 0
    fi

    # Try gammastep
    if command -v gammastep &>/dev/null; then
        pkill gammastep 2>/dev/null || true
        sleep 0.2
        gammastep -O "${temp}" &>/dev/null &
        disown
        echo "gammastep:${temp}" > "${NIGHT_STATE}"
        return 0
    fi

    # Try Hyprland shader
    if [[ -f "${SHADERS_DIR}/blue-light-filter.glsl" ]]; then
        hyprctl keyword decoration:screen_shader "${SHADERS_DIR}/blue-light-filter.glsl" 2>/dev/null
        echo "shader:blue-light" > "${NIGHT_STATE}"
        return 0
    fi

    echo "off" > "${NIGHT_STATE}"
    log "WARN" "No night light backend available"
    return 1
}

night_disable() {
    log "INFO" "Disabling night light"

    pkill wlsunset   2>/dev/null || true
    pkill gammastep  2>/dev/null || true

    # Reset Hyprland shader
    hyprctl keyword decoration:screen_shader "" 2>/dev/null || true

    echo "off" > "${NIGHT_STATE}"
    ok "Night light disabled"
}

night_toggle() {
    local state
    state=$(get_night_state)

    if [[ "${state}" == "off" ]]; then
        night_enable 4000
        notify-send "🌙 Night Light" "Enabled (4000K)" \
            --app-name="ASH Display" --expire-time=2000 2>/dev/null || true
    else
        night_disable
        notify-send "☀️ Night Light" "Disabled" \
            --app-name="ASH Display" --expire-time=2000 2>/dev/null || true
    fi
}

night_warmer() {
    local state
    state=$(get_night_state)
    local current_temp=6500

    if [[ "${state}" != "off" ]]; then
        current_temp=$(echo "${state}" | grep -oP '\d+' || echo "4000")
    fi

    local new_temp=$(( current_temp - 500 ))
    (( new_temp < 1000 )) && new_temp=1000

    night_enable "${new_temp}"
    notify-send "🌙 Night Light" "Temperature: ${new_temp}K (warmer)" \
        --app-name="ASH Display" --expire-time=2000 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎬 SCREEN SHADERS
# ═══════════════════════════════════════════════════════════════════════════════

declare -a SHADER_CYCLE=(
    ""                                          # Off
    "${SHADERS_DIR}/blue-light-filter.glsl"    # Blue light filter
    "${SHADERS_DIR}/vibrance.glsl"              # Vibrance boost
    "${SHADERS_DIR}/crt.glsl"                  # CRT effect
)

SHADER_NAMES=(
    "None"
    "Blue Light Filter"
    "Vibrance Boost"
    "CRT Effect"
)

get_shader_index() {
    [[ -f "${SHADER_STATE}" ]] && cat "${SHADER_STATE}" || echo "0"
}

shader_cycle() {
    local current
    current=$(get_shader_index)
    local next=$(( (current + 1) % ${#SHADER_CYCLE[@]} ))

    local shader="${SHADER_CYCLE[${next}]}"
    local shader_name="${SHADER_NAMES[${next}]}"

    if [[ -n "${shader}" ]] && [[ -f "${shader}" ]]; then
        hyprctl keyword decoration:screen_shader "${shader}" 2>/dev/null
    else
        hyprctl keyword decoration:screen_shader "" 2>/dev/null
    fi

    echo "${next}" > "${SHADER_STATE}"

    notify-send "🎬 Screen Shader" "${shader_name}" \
        --app-name="ASH Display" --expire-time=2000 2>/dev/null || true

    log "INFO" "Shader: ${shader_name}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🖥️ DPMS CONTROL
# ═══════════════════════════════════════════════════════════════════════════════

dpms_off() {
    hyprctl dispatch dpms off 2>/dev/null
    log "INFO" "DPMS off"
}

dpms_on() {
    hyprctl dispatch dpms on 2>/dev/null
    log "INFO" "DPMS on"
}

dpms_toggle() {
    # Check current DPMS state
    local monitor_state
    monitor_state=$(hyprctl monitors -j 2>/dev/null \
        | jq -r '.[0].dpmsStatus' 2>/dev/null || echo "true")

    if [[ "${monitor_state}" == "true" ]]; then
        dpms_off
    else
        dpms_on
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

main() {
    local action="${1:-status}"
    shift || true

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        night-toggle)   night_toggle ;;
        night-enable)   night_enable "${1:-4000}" ;;
        night-disable)  night_disable ;;
        night-warmer)   night_warmer ;;
        shader-cycle)   shader_cycle ;;
        dpms-off)       dpms_off ;;
        dpms-on)        dpms_on ;;
        dpms-toggle)    dpms_toggle ;;
        status)
            local night_state shader_idx
            night_state=$(get_night_state)
            shader_idx=$(get_shader_index)
            echo "Night light: ${night_state}"
            echo "Shader: ${SHADER_NAMES[${shader_idx}]}"
            ;;
        *)
            echo "Usage: dpms.sh [night-toggle|night-enable|night-disable|night-warmer"
            echo "                |shader-cycle|dpms-off|dpms-on|dpms-toggle|status]"
            exit 1
            ;;
    esac
}

main "$@"