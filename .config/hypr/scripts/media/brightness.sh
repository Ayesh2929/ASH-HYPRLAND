#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — BRIGHTNESS CONTROL                           ║
# ║           Multi-backend: brightnessctl, light, xbacklight + OSD            ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: brightness.sh [ACTION] [VALUE]
#
# ACTIONS:
#   up    N  — Increase brightness by N% (default 5)
#   down  N  — Decrease brightness by N%
#   set   N  — Set brightness to exactly N%
#   get      — Print current brightness percentage
#   status   — JSON output for Waybar
#   night    — Toggle night mode (reduce to 30%)
#   max      — Set to 100%
#   min      — Set to minimum (1%)

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/brightness.log"
readonly STATE_FILE="${CACHE_DIR}/brightness-state.txt"
readonly WAYBAR_SIGNAL=9
readonly MIN_BRIGHTNESS=1
readonly MAX_BRIGHTNESS=100

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔍 BACKEND DETECTION
# ═══════════════════════════════════════════════════════════════════════════════

detect_backend() {
    if command -v brightnessctl &>/dev/null; then
        # Verify it can actually control brightness
        if brightnessctl info &>/dev/null 2>&1; then
            echo "brightnessctl"
            return
        fi
    fi

    if command -v light &>/dev/null; then
        if light -G &>/dev/null 2>&1; then
            echo "light"
            return
        fi
    fi

    if command -v xbacklight &>/dev/null; then
        if xbacklight -get &>/dev/null 2>&1; then
            echo "xbacklight"
            return
        fi
    fi

    # DDC/CI for external monitors
    if command -v ddcutil &>/dev/null; then
        echo "ddcutil"
        return
    fi

    # Kernel sysfs fallback
    local sysfs_path
    sysfs_path=$(find /sys/class/backlight -maxdepth 1 -mindepth 1 2>/dev/null | head -1)
    if [[ -n "${sysfs_path}" ]]; then
        echo "sysfs:${sysfs_path}"
        return
    fi

    echo "none"
}

readonly BACKEND=$(detect_backend)

# ═══════════════════════════════════════════════════════════════════════════════
# 💡 BRIGHTNESS OPERATIONS
# ═══════════════════════════════════════════════════════════════════════════════

get_brightness() {
    case "${BACKEND}" in
        brightnessctl)
            brightnessctl -m 2>/dev/null | cut -d, -f4 | tr -d '%'
            ;;
        light)
            light -G 2>/dev/null | awk '{printf "%.0f", $1}'
            ;;
        xbacklight)
            xbacklight -get 2>/dev/null | awk '{printf "%.0f", $1}'
            ;;
        ddcutil)
            ddcutil getvcp 10 2>/dev/null \
                | grep -oP 'current value =\s*\K\d+' \
                | head -1 || echo "50"
            ;;
        sysfs:*)
            local path="${BACKEND#sysfs:}"
            local max current
            max=$(cat "${path}/max_brightness" 2>/dev/null || echo "100")
            current=$(cat "${path}/brightness" 2>/dev/null || echo "50")
            echo $(( current * 100 / max ))
            ;;
        *)
            echo "100"
            ;;
    esac
}

set_brightness() {
    local pct="$1"

    # Clamp value
    (( pct < MIN_BRIGHTNESS )) && pct=${MIN_BRIGHTNESS}
    (( pct > MAX_BRIGHTNESS )) && pct=${MAX_BRIGHTNESS}

    case "${BACKEND}" in
        brightnessctl)
            brightnessctl set "${pct}%" 2>/dev/null
            ;;
        light)
            light -S "${pct}" 2>/dev/null
            ;;
        xbacklight)
            xbacklight -set "${pct}" 2>/dev/null
            ;;
        ddcutil)
            ddcutil setvcp 10 "${pct}" 2>/dev/null
            ;;
        sysfs:*)
            local path="${BACKEND#sysfs:}"
            local max
            max=$(cat "${path}/max_brightness" 2>/dev/null || echo "100")
            local raw=$(( pct * max / 100 ))
            echo "${raw}" | sudo tee "${path}/brightness" > /dev/null 2>&1 || true
            ;;
    esac

    # Save state
    echo "${pct}" > "${STATE_FILE}" 2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌟 SMOOTH BRIGHTNESS TRANSITION
# ═══════════════════════════════════════════════════════════════════════════════

smooth_set() {
    local target="$1"
    local current
    current=$(get_brightness)
    local steps=8
    local diff=$(( target - current ))

    if (( diff == 0 )); then
        return 0
    fi

    local step_size=$(( diff / steps ))
    (( step_size == 0 )) && step_size=$(( diff > 0 ? 1 : -1 ))

    local val="${current}"
    for (( i=0; i<steps; i++ )); do
        val=$(( val + step_size ))
        (( val < MIN_BRIGHTNESS )) && val=${MIN_BRIGHTNESS}
        (( val > MAX_BRIGHTNESS )) && val=${MAX_BRIGHTNESS}
        set_brightness "${val}"
        sleep 0.02
    done

    # Ensure exact target is set
    set_brightness "${target}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📣 OSD DISPLAY
# ═══════════════════════════════════════════════════════════════════════════════

show_osd() {
    local brightness="$1"

    # Get appropriate icon
    local icon
    if (( brightness <= 25 )); then
        icon="display-brightness-low-symbolic"
    elif (( brightness <= 50 )); then
        icon="display-brightness-medium-symbolic"
    elif (( brightness <= 75 )); then
        icon="display-brightness-high-symbolic"
    else
        icon="display-brightness-symbolic"
    fi

    # Try swayosd first
    if command -v swayosd-client &>/dev/null; then
        swayosd-client --brightness "${brightness}" 2>/dev/null || true
        return 0
    fi

    # Fallback: dunst notification
    local bar=""
    local filled=$(( brightness / 5 ))
    local empty=$(( 20 - filled ))
    for (( i=0; i<filled; i++ )); do bar+="█"; done
    for (( i=0; i<empty; i++ )); do bar+="░"; done

    notify-send "☀️ Brightness: ${brightness}%" \
        "${bar}" \
        --icon="${icon}" \
        --app-name="Brightness" \
        --expire-time=1200 \
        --hint=int:value:"${brightness}" \
        --hint=string:synchronous:brightness \
        2>/dev/null || true
}

# ═══════════════════════════════════════════════════════════════════════════════
# 📡 WAYBAR STATUS
# ═══════════════════════════════════════════════════════════════════════════════

signal_waybar() {
    pkill -SIGRTMIN+${WAYBAR_SIGNAL} waybar 2>/dev/null || true
}

status_json() {
    local brightness
    brightness=$(get_brightness)

    local icon
    if (( brightness <= 25 )); then
        icon="󰃞"
        class="low"
    elif (( brightness <= 50 )); then
        icon="󰃟"
        class="medium"
    elif (( brightness <= 75 )); then
        icon="󰃠"
        class="high"
    else
        icon="󰃠"
        class="max"
    fi

    printf '{"text": "%s %s%%", "tooltip": "Brightness: %s%%\nBackend: %s", "class": "%s", "percentage": %s}\n' \
        "${icon}" "${brightness}" "${brightness}" "${BACKEND}" "${class}" "${brightness}"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🌙 NIGHT MODE
# ═══════════════════════════════════════════════════════════════════════════════

toggle_night() {
    local night_brightness=30
    local current
    current=$(get_brightness)

    if [[ -f "${STATE_FILE}.pre-night" ]]; then
        # Restore from night mode
        local saved
        saved=$(cat "${STATE_FILE}.pre-night")
        rm -f "${STATE_FILE}.pre-night"
        smooth_set "${saved}"
        notify-send "☀️ Night Mode" "Disabled — ${saved}%" \
            --app-name="Brightness" --expire-time=2000 2>/dev/null || true
        show_osd "${saved}"
        log "INFO" "Night mode OFF → ${saved}%"
    else
        # Enable night mode
        echo "${current}" > "${STATE_FILE}.pre-night"
        smooth_set "${night_brightness}"
        notify-send "🌙 Night Mode" "Enabled — ${night_brightness}%" \
            --app-name="Brightness" --expire-time=2000 2>/dev/null || true
        show_osd "${night_brightness}"
        log "INFO" "Night mode ON → ${night_brightness}%"
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local action="${1:-status}"
    local value="${2:-5}"

    mkdir -p "${CACHE_DIR}/logs"

    if [[ "${BACKEND}" == "none" ]]; then
        echo '{"text": "󰃞 N/A", "class": "unavailable"}'
        exit 0
    fi

    case "${action}" in
        up)
            local current
            current=$(get_brightness)
            local new=$(( current + value ))
            smooth_set "${new}"
            local final
            final=$(get_brightness)
            show_osd "${final}"
            signal_waybar
            log "INFO" "Brightness up +${value}% → ${final}%"
            ;;

        down)
            local current
            current=$(get_brightness)
            local new=$(( current - value ))
            smooth_set "${new}"
            local final
            final=$(get_brightness)
            show_osd "${final}"
            signal_waybar
            log "INFO" "Brightness down -${value}% → ${final}%"
            ;;

        set)
            smooth_set "${value}"
            local final
            final=$(get_brightness)
            show_osd "${final}"
            signal_waybar
            log "INFO" "Brightness set to ${value}% → ${final}%"
            ;;

        get)
            get_brightness
            ;;

        max)
            smooth_set 100
            show_osd 100
            signal_waybar
            log "INFO" "Brightness max → 100%"
            ;;

        min)
            smooth_set "${MIN_BRIGHTNESS}"
            show_osd "${MIN_BRIGHTNESS}"
            signal_waybar
            log "INFO" "Brightness min → ${MIN_BRIGHTNESS}%"
            ;;

        night | night-toggle)
            toggle_night
            signal_waybar
            ;;

        status)
            status_json
            ;;

        backend)
            echo "${BACKEND}"
            ;;

        *)
            echo "Usage: brightness.sh [up|down|set|get|max|min|night|status] [value]" >&2
            exit 1
            ;;
    esac
}

main "$@"