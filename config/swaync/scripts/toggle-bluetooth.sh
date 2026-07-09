#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — SwayNC Ultra Bluetooth Toggle Script             ║
# ║  Premium Bluetooth controller with device scanning, pairing wizard,          ║
# ║  battery tracking, audio profile management, device history,                 ║
# ║  multi-adapter support, and intelligent auto-reconnect engine                ║
# ║                                                                              ║
# ║  Author  : ash-dotfiles                                                      ║
# ║  Version : 5.0.0                                                             ║
# ║  License : MIT                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONSTANTS & PATHS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly SCRIPT_NAME="ash-bluetooth-toggle"
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG directories
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"

# State & data files
readonly BT_STATE_FILE="${CACHE_DIR}/bluetooth.state"
readonly BT_LOCK_FILE="${RUNTIME_DIR}/bluetooth.lock"
readonly BT_LOG_FILE="${CACHE_DIR}/logs/bluetooth.log"
readonly BT_HISTORY_FILE="${DATA_DIR}/bluetooth-history.json"
readonly BT_STATS_FILE="${CACHE_DIR}/bluetooth-stats.json"
readonly BT_DEVICES_FILE="${CACHE_DIR}/bluetooth-devices.json"
readonly BT_PROFILES_FILE="${CONFIG_DIR}/bluetooth-profiles.json"
readonly BT_BATTERY_FILE="${CACHE_DIR}/bluetooth-battery.json"
readonly BT_SCAN_PID_FILE="${RUNTIME_DIR}/bt-scan.pid"
readonly BT_PAIR_STATE_FILE="${RUNTIME_DIR}/bt-pair.state"
readonly BT_RECONNECT_FILE="${CACHE_DIR}/bluetooth-reconnect.json"
readonly BT_TRUSTED_FILE="${CONFIG_DIR}/bluetooth-trusted.json"

# Sound files
readonly SOUND_CONNECT="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/bluetooth-connect.ogg"
readonly SOUND_DISCONNECT="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/notification.ogg"
readonly SOUND_PAIR="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/success.ogg"
readonly SOUND_ERROR="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/error.ogg"

# Icons — Nerd Fonts
readonly ICON_BT_ON="󰂯"
readonly ICON_BT_OFF="󰂲"
readonly ICON_BT_CONNECTED="󰂱"
readonly ICON_BT_PAIRING="󰂴"
readonly ICON_BT_SCANNING="󰂯"
readonly ICON_BT_AUDIO="󰂰"
readonly ICON_BT_HEADPHONES="󰋋"
readonly ICON_BT_HEADSET="󰋎"
readonly ICON_BT_EARBUDS="󰟑"
readonly ICON_BT_SPEAKERS="󰓃"
readonly ICON_BT_KEYBOARD="󰌌"
readonly ICON_BT_MOUSE="󰦋"
readonly ICON_BT_GAMEPAD="󰊗"
readonly ICON_BT_PHONE="󰄜"
readonly ICON_BT_WATCH="󱑻"
readonly ICON_BT_COMPUTER="󰇄"
readonly ICON_BT_DEFAULT="󰂯"
readonly ICON_BATTERY_FULL="󰁹"
readonly ICON_BATTERY_HIGH="󰂁"
readonly ICON_BATTERY_MID="󰁾"
readonly ICON_BATTERY_LOW="󰁻"
readonly ICON_BATTERY_CRIT="󰂎"
readonly ICON_CODEC="󱑽"
readonly ICON_TRUST="󰕶"
readonly ICON_BLOCK="󱏔"
readonly ICON_SUCCESS="󰄬"
readonly ICON_ERROR="󰅙"
readonly ICON_WARNING="󰀦"
readonly ICON_INFO="󰋼"
readonly ICON_ASH="󱎫"
readonly ICON_SEND="󰈔"

# ANSI colors
readonly CLR_RESET='\033[0m'
readonly CLR_BOLD='\033[1m'
readonly CLR_DIM='\033[2m'
readonly CLR_RED='\033[0;31m'
readonly CLR_GREEN='\033[0;32m'
readonly CLR_YELLOW='\033[0;33m'
readonly CLR_BLUE='\033[0;34m'
readonly CLR_MAGENTA='\033[0;35m'
readonly CLR_CYAN='\033[0;36m'
readonly CLR_WHITE='\033[0;37m'
readonly CLR_GRAY='\033[0;90m'
readonly CLR_BRIGHT_BLUE='\033[0;94m'

# Timeouts
readonly CONNECT_TIMEOUT=15
readonly SCAN_TIMEOUT=30
readonly PAIR_TIMEOUT=60
readonly RECONNECT_DELAY=3
readonly MAX_RECONNECT_ATTEMPTS=3

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR"
        "$STATE_DIR"
        "$DATA_DIR"
        "$CONFIG_DIR"
        "$RUNTIME_DIR"
        "${CACHE_DIR}/logs"
    )
    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || mkdir -p "$dir"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOGGING ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_log() {
    local level="$1"; shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S.%3N')"
    local log_line="[$timestamp] [$$] [$level] $message"

    # Log rotation at 512KB
    if [[ -f "$BT_LOG_FILE" ]]; then
        local sz
        sz="$(stat -c%s "$BT_LOG_FILE" 2>/dev/null || echo 0)"
        if (( sz > 524288 )); then
            mv "$BT_LOG_FILE" "${BT_LOG_FILE}.$(date +%Y%m%d_%H%M%S).old"
            find "${CACHE_DIR}/logs" -name 'bluetooth.log.*.old' \
                -mtime +7 -delete 2>/dev/null || true
        fi
    fi

    echo "$log_line" >> "$BT_LOG_FILE" 2>/dev/null || true

    [[ ! -t 2 ]] && return 0
    case "$level" in
        ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[✗]${CLR_RESET} $message" >&2 ;;
        WARN)    echo -e "${CLR_YELLOW}[⚠]${CLR_RESET} $message" >&2 ;;
        INFO)    echo -e "${CLR_CYAN}[ℹ]${CLR_RESET} $message" >&2 ;;
        SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[✓]${CLR_RESET} $message" >&2 ;;
        DEBUG)
            [[ "${ASH_DEBUG:-0}" == "1" ]] && \
                echo -e "${CLR_GRAY}[~] $message${CLR_RESET}" >&2
            ;;
    esac
}

log_info()    { _log INFO    "$@"; }
log_warn()    { _log WARN    "$@"; }
log_error()   { _log ERROR   "$@"; }
log_success() { _log SUCCESS "$@"; }
log_debug()   { _log DEBUG   "$@"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOCK MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_acquire_lock() {
    local max_wait="${1:-5}"
    local waited=0

    while [[ -f "$BT_LOCK_FILE" ]]; do
        local lock_pid
        lock_pid="$(cat "$BT_LOCK_FILE" 2>/dev/null || echo '')"
        if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
            log_warn "Removing stale lock (PID=$lock_pid)"
            rm -f "$BT_LOCK_FILE"
            break
        fi
        if (( waited >= max_wait )); then
            log_error "Lock timeout after ${max_wait}s"
            return 1
        fi
        sleep 0.25
        (( waited++ )) || true
    done

    echo "$$" > "$BT_LOCK_FILE"
    log_debug "Lock acquired PID=$$"
    return 0
}

_release_lock() {
    [[ "$(cat "$BT_LOCK_FILE" 2>/dev/null)" == "$$" ]] && \
        rm -f "$BT_LOCK_FILE"
    log_debug "Lock released"
}

_cleanup() {
    _release_lock
    rm -f "${RUNTIME_DIR}/bt-temp-$$"*
    log_debug "Cleanup complete"
}

trap '_cleanup' EXIT INT TERM HUP

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEPENDENCY CHECKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_deps() {
    local required=("bluetoothctl" "notify-send" "jq")
    local missing=()

    for cmd in "${required[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "Missing required dependencies: ${missing[*]}"
        notify-send -u critical \
            "${ICON_ERROR} ASH Bluetooth" \
            "Missing: ${missing[*]}" 2>/dev/null || true
        exit 1
    fi

    # Check bluetoothd is running
    if ! systemctl is-active --quiet bluetooth 2>/dev/null; then
        log_warn "bluetooth service not active — attempting start"
        if command -v pkexec &>/dev/null; then
            pkexec systemctl start bluetooth &>/dev/null || true
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SOUND ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_play_sound() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0

    if   command -v pw-play   &>/dev/null; then
        pw-play   --volume=0.45 "$file" &>/dev/null &
    elif command -v paplay    &>/dev/null; then
        paplay    --volume=29491 "$file" &>/dev/null &
    elif command -v ogg123    &>/dev/null; then
        ogg123    -q "$file" &>/dev/null &
    elif command -v ffplay    &>/dev/null; then
        ffplay    -nodisp -autoexit -volume 45 "$file" &>/dev/null &
    fi
    disown 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NOTIFICATION ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_notify() {
    local title="$1"
    local body="${2:-}"
    local urgency="${3:-normal}"
    local expire="${4:-4500}"
    local icon="${5:-bluetooth-symbolic}"
    local hint="${6:-}"

    local args=(
        --urgency="$urgency"
        --expire-time="$expire"
        --app-name="ASH Bluetooth"
        --icon="$icon"
    )

    [[ -n "$hint"  ]] && args+=(--hint="$hint")

    notify-send "${args[@]}" "$title" "$body" 2>/dev/null || true
    log_debug "Notify: $title — $body"
}

_notify_bt_on() {
    local connected_count="${1:-0}"
    local body="Bluetooth adapter enabled"
    (( connected_count > 0 )) && body+="  •  ${connected_count} device(s) connected"

    _notify \
        "${ICON_BT_ON}  Bluetooth On" \
        "$body" \
        "low" "3500"
}

_notify_bt_off() {
    local was_connected="${1:-}"
    local body="Bluetooth adapter disabled"
    [[ -n "$was_connected" ]] && body+="  •  Disconnected: $was_connected"

    _notify \
        "${ICON_BT_OFF}  Bluetooth Off" \
        "$body" \
        "low" "3500"
}

_notify_connected() {
    local name="$1"
    local mac="$2"
    local device_type="${3:-device}"
    local battery="${4:-}"
    local codec="${5:-}"

    local icon
    icon="$(_device_icon "$device_type")"
    local body="${icon}  ${name}  •  ${device_type}"
    [[ -n "$battery" ]] && body+="  •  $(_battery_icon "$battery") ${battery}%"
    [[ -n "$codec"   ]] && body+="  •  ${ICON_CODEC} ${codec}"

    _notify \
        "${ICON_BT_CONNECTED}  Connected" \
        "$body" \
        "low" "4500"

    _play_sound "$SOUND_CONNECT"
}

_notify_disconnected() {
    local name="$1"
    local reason="${2:-}"
    local body="$name"
    [[ -n "$reason" ]] && body+="  •  $reason"

    _notify \
        "${ICON_BT_OFF}  Disconnected" \
        "$body" \
        "normal" "3500"

    _play_sound "$SOUND_DISCONNECT"
}

_notify_paired() {
    local name="$1"
    local mac="$2"

    _notify \
        "${ICON_BT_PAIRING}  Device Paired" \
        "${ICON_SUCCESS}  ${name} paired successfully" \
        "low" "5000"

    _play_sound "$SOUND_PAIR"
}

_notify_pairing_request() {
    local name="$1"
    local pin="${2:-}"
    local body="Pairing request from: ${name}"
    [[ -n "$pin" ]] && body+="\nPIN: ${pin}"

    notify-send \
        --urgency=critical \
        --expire-time=30000 \
        --app-name="ASH Bluetooth" \
        --icon="bluetooth-symbolic" \
        --action="Accept=bluetoothctl confirm yes" \
        --action="Reject=bluetoothctl confirm no" \
        "${ICON_BT_PAIRING}  Pairing Request" \
        "$body" 2>/dev/null || true
}

_notify_battery_low() {
    local name="$1"
    local battery="$2"

    _notify \
        "${ICON_BATTERY_CRIT}  Low Battery" \
        "${name}: ${battery}% — please charge soon" \
        "normal" "6000"
}

_notify_battery_critical() {
    local name="$1"
    local battery="$2"

    _notify \
        "${ICON_BATTERY_CRIT}  Critical Battery" \
        "${name}: ${battery}% — connect charger now!" \
        "critical" "0"
}

_notify_error() {
    local title="$1"
    local body="${2:-}"

    _notify \
        "${ICON_ERROR}  BT Error — $title" \
        "$body" \
        "critical" "6000"

    _play_sound "$SOUND_ERROR"
}

_notify_profile_changed() {
    local device="$1"
    local profile="$2"

    _notify \
        "${ICON_CODEC}  Audio Profile" \
        "${device}  →  ${profile}" \
        "low" "3000"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ADAPTER MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_adapter() {
    # Returns primary adapter MAC (e.g., 00:11:22:33:44:55)
    bluetoothctl show 2>/dev/null \
        | grep 'Controller' \
        | head -1 \
        | awk '{print $2}' || echo ''
}

_get_adapter_name() {
    bluetoothctl show 2>/dev/null \
        | grep '^\s*Name:' \
        | head -1 \
        | awk '{$1=""; print $0}' \
        | xargs || echo 'Bluetooth Adapter'
}

_get_bt_state() {
    local powered
    powered="$(bluetoothctl show 2>/dev/null \
        | grep 'Powered:' \
        | awk '{print $2}')"

    case "${powered:-no}" in
        yes) echo "on"  ;;
        no)  echo "off" ;;
        *)   echo "off" ;;
    esac
}

_get_discovering_state() {
    bluetoothctl show 2>/dev/null \
        | grep 'Discovering:' \
        | awk '{print $2}' || echo "no"
}

_get_discoverable_state() {
    bluetoothctl show 2>/dev/null \
        | grep 'Discoverable:' \
        | awk '{print $2}' || echo "no"
}

_get_pairable_state() {
    bluetoothctl show 2>/dev/null \
        | grep 'Pairable:' \
        | awk '{print $2}' || echo "no"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEVICE QUERIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_connected_devices() {
    # Returns JSON array of connected devices
    local devices_json='[]'
    local raw

    raw="$(bluetoothctl devices Connected 2>/dev/null)" || return 0

    while IFS=' ' read -r _ mac name_rest; do
        [[ -z "$mac" ]] && continue
        local name="${name_rest}"

        local dev_info
        dev_info="$(bluetoothctl info "$mac" 2>/dev/null)"

        local trusted paired
        trusted="$(echo "$dev_info" | grep 'Trusted:' | awk '{print $2}')"
        paired="$(echo "$dev_info"  | grep 'Paired:'  | awk '{print $2}')"

        local device_class
        device_class="$(_detect_device_type "$mac" "$dev_info")"

        local battery=0
        battery="$(_get_device_battery "$mac")"

        local rssi=0
        rssi="$(echo "$dev_info" \
            | grep 'RSSI:' \
            | awk '{print $2}' || echo '0')"

        local icon
        icon="$(_device_icon "$device_class")"

        devices_json="$(echo "$devices_json" | jq \
            --arg mac      "$mac" \
            --arg name     "$name" \
            --arg type     "$device_class" \
            --arg icon     "$icon" \
            --argjson batt "$battery" \
            --argjson rssi "$rssi" \
            --arg trusted  "${trusted:-no}" \
            --arg paired   "${paired:-no}" \
            '. += [{
                "mac":       $mac,
                "name":      $name,
                "type":      $type,
                "icon":      $icon,
                "battery":   $batt,
                "rssi":      $rssi,
                "trusted":   ($trusted == "yes"),
                "paired":    ($paired  == "yes"),
                "connected": true
            }]' 2>/dev/null)"
    done <<< "$raw"

    echo "$devices_json"
}

_get_paired_devices() {
    local devices_json='[]'
    local raw

    raw="$(bluetoothctl devices Paired 2>/dev/null)" || return 0

    while IFS=' ' read -r _ mac name_rest; do
        [[ -z "$mac" ]] && continue

        local dev_info
        dev_info="$(bluetoothctl info "$mac" 2>/dev/null)"

        local connected
        connected="$(echo "$dev_info" | grep 'Connected:' | awk '{print $2}')"

        local device_class
        device_class="$(_detect_device_type "$mac" "$dev_info")"

        local icon
        icon="$(_device_icon "$device_class")"

        local battery=0
        battery="$(_get_device_battery "$mac")"

        devices_json="$(echo "$devices_json" | jq \
            --arg mac       "$mac" \
            --arg name      "$name_rest" \
            --arg type      "$device_class" \
            --arg icon      "$icon" \
            --argjson batt  "$battery" \
            --argjson conn  "$([ "$connected" = "yes" ] && echo true || echo false)" \
            '. += [{
                "mac":       $mac,
                "name":      $name,
                "type":      $type,
                "icon":      $icon,
                "battery":   $batt,
                "connected": $conn,
                "paired":    true
            }]' 2>/dev/null)"
    done <<< "$raw"

    echo "$devices_json"
}

_get_nearby_devices() {
    # Scan and return devices found in range
    local devices_json='[]'
    local raw

    raw="$(bluetoothctl devices 2>/dev/null)" || return 0

    while IFS=' ' read -r _ mac name_rest; do
        [[ -z "$mac" ]] && continue

        local dev_info
        dev_info="$(bluetoothctl info "$mac" 2>/dev/null)"

        local connected paired trusted
        connected="$(echo "$dev_info" | grep 'Connected:' | awk '{print $2}')"
        paired="$(echo "$dev_info"    | grep 'Paired:'    | awk '{print $2}')"
        trusted="$(echo "$dev_info"   | grep 'Trusted:'   | awk '{print $2}')"

        local rssi=0
        rssi="$(echo "$dev_info" | grep 'RSSI:' | awk '{print $2}' || echo 0)"

        local device_class
        device_class="$(_detect_device_type "$mac" "$dev_info")"

        local icon
        icon="$(_device_icon "$device_class")"

        devices_json="$(echo "$devices_json" | jq \
            --arg mac       "$mac" \
            --arg name      "$name_rest" \
            --arg type      "$device_class" \
            --arg icon      "$icon" \
            --argjson rssi  "${rssi:-0}" \
            --argjson conn  "$([ "$connected" = "yes" ] && echo true || echo false)" \
            --argjson pair  "$([ "$paired"    = "yes" ] && echo true || echo false)" \
            --argjson trust "$([ "$trusted"   = "yes" ] && echo true || echo false)" \
            '. += [{
                "mac":       $mac,
                "name":      $name,
                "type":      $type,
                "icon":      $icon,
                "rssi":      $rssi,
                "connected": $conn,
                "paired":    $pair,
                "trusted":   $trust
            }]' 2>/dev/null)"
    done <<< "$raw"

    # Sort: connected first, then paired, then by RSSI
    echo "$devices_json" | jq '
        sort_by(
            [
                (if .connected then 0 else 1 end),
                (if .paired    then 0 else 1 end),
                -(.rssi | tonumber)
            ]
        )
    ' 2>/dev/null
}

_get_device_battery() {
    local mac="$1"
    local mac_clean
    mac_clean="${mac//:/}"

    # Try UPower first
    if command -v upower &>/dev/null; then
        local upower_path
        upower_path="$(upower -e 2>/dev/null \
            | grep -i "bluetooth.*${mac_clean,,}" \
            | head -1)"

        if [[ -n "$upower_path" ]]; then
            local batt
            batt="$(upower -i "$upower_path" 2>/dev/null \
                | grep 'percentage:' \
                | awk '{print $2}' \
                | tr -d '%')"
            echo "${batt:-0}"
            return 0
        fi
    fi

    # Try bluetoothctl battery attribute
    local batt
    batt="$(bluetoothctl info "$mac" 2>/dev/null \
        | grep -i 'battery percentage' \
        | grep -oP '\d+' \
        | head -1)"
    echo "${batt:-0}"
}

_detect_device_type() {
    local mac="$1"
    local dev_info="${2:-}"

    [[ -z "$dev_info" ]] && \
        dev_info="$(bluetoothctl info "$mac" 2>/dev/null)"

    local icon_class
    icon_class="$(echo "$dev_info" \
        | grep 'Icon:' \
        | awk '{print $2}' \
        | tr -d '\r')"

    local class_hex
    class_hex="$(echo "$dev_info" \
        | grep 'Class:' \
        | awk '{print $2}' \
        | tr -d '\r')"

    local name
    name="$(echo "$dev_info" \
        | grep '^\s*Name:' \
        | awk '{$1=""; print $0}' \
        | xargs | tr '[:upper:]' '[:lower:]')"

    # Classify by icon
    case "${icon_class:-}" in
        audio-headphones)          echo "headphones";  return ;;
        audio-headset)             echo "headset";     return ;;
        audio-card)                echo "speakers";    return ;;
        input-keyboard)            echo "keyboard";    return ;;
        input-mouse)               echo "mouse";       return ;;
        input-gaming)              echo "gamepad";     return ;;
        phone)                     echo "phone";       return ;;
        computer)                  echo "computer";    return ;;
        watch)                     echo "watch";       return ;;
        video-display)             echo "tv";          return ;;
    esac

    # Classify by class hex
    if [[ -n "$class_hex" ]]; then
        local class_dec
        class_dec="$(printf '%d' "$class_hex" 2>/dev/null || echo 0)"
        local major=$(( (class_dec >> 8) & 0x1F ))
        case "$major" in
            4)  echo "audio";    return ;;
            5)  echo "keyboard"; return ;;
            1)  echo "computer"; return ;;
            2)  echo "phone";    return ;;
        esac
    fi

    # Classify by name patterns
    if echo "$name" | grep -qiE \
        'headphone|earbud|airpod|bud|wh-|wf-|momentum|soundcore'; then
        echo "headphones"; return
    fi
    if echo "$name" | grep -qiE \
        'headset|jabra|plantronics|poly'; then
        echo "headset"; return
    fi
    if echo "$name" | grep -qiE \
        'speaker|soundbar|jbl|bose|harman|ultimate ears|ue boom'; then
        echo "speakers"; return
    fi
    if echo "$name" | grep -qiE \
        'keyboard|kb|k[0-9]{3}|mx keys'; then
        echo "keyboard"; return
    fi
    if echo "$name" | grep -qiE \
        'mouse|mx master|anywhere|m[0-9]{3}'; then
        echo "mouse"; return
    fi
    if echo "$name" | grep -qiE \
        'controller|gamepad|xbox|dualshock|dualsense|ps[345]|8bitdo'; then
        echo "gamepad"; return
    fi
    if echo "$name" | grep -qiE \
        'watch|band|fitness|galaxy watch|apple watch|garmin'; then
        echo "watch"; return
    fi
    if echo "$name" | grep -qiE \
        'iphone|android|samsung|pixel|oneplus|xiaomi'; then
        echo "phone"; return
    fi

    echo "device"
}

_device_icon() {
    local type="${1:-device}"
    case "$type" in
        headphones) echo "$ICON_BT_HEADPHONES" ;;
        headset)    echo "$ICON_BT_HEADSET"    ;;
        earbuds)    echo "$ICON_BT_EARBUDS"    ;;
        speakers)   echo "$ICON_BT_SPEAKERS"   ;;
        audio)      echo "$ICON_BT_AUDIO"      ;;
        keyboard)   echo "$ICON_BT_KEYBOARD"   ;;
        mouse)      echo "$ICON_BT_MOUSE"      ;;
        gamepad)    echo "$ICON_BT_GAMEPAD"    ;;
        phone)      echo "$ICON_BT_PHONE"      ;;
        watch)      echo "$ICON_BT_WATCH"      ;;
        computer)   echo "$ICON_BT_COMPUTER"   ;;
        *)          echo "$ICON_BT_DEFAULT"    ;;
    esac
}

_battery_icon() {
    local pct="${1:-0}"
    if   (( pct >= 90 )); then echo "$ICON_BATTERY_FULL"
    elif (( pct >= 60 )); then echo "$ICON_BATTERY_HIGH"
    elif (( pct >= 30 )); then echo "$ICON_BATTERY_MID"
    elif (( pct >= 15 )); then echo "$ICON_BATTERY_LOW"
    else                       echo "$ICON_BATTERY_CRIT"
    fi
}

_battery_color() {
    local pct="${1:-0}"
    if   (( pct >= 60 )); then echo "$CLR_GREEN"
    elif (( pct >= 30 )); then echo "$CLR_YELLOW"
    else                       echo "$CLR_RED"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAYBAR SIGNAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_waybar() {
    pkill -SIGRTMIN+7 waybar 2>/dev/null || true
    log_debug "Waybar signaled SIGRTMIN+7"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANALYTICS & HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_record_event() {
    local event="$1"
    local metadata="${2:-{}}"
    local timestamp
    timestamp="$(date -Iseconds)"

    [[ ! -f "$BT_HISTORY_FILE" ]] && \
        echo '{"events":[],"devices":{}}' > "$BT_HISTORY_FILE"

    local updated
    updated="$(jq \
        --arg  event "$event" \
        --arg  ts    "$timestamp" \
        --argjson meta "$metadata" \
        '.events += [{
            "event":     $event,
            "timestamp": $ts,
            "metadata":  $meta
        }] | .events = .events[-1000:]' \
        "$BT_HISTORY_FILE" 2>/dev/null)" || return 0

    echo "$updated" > "$BT_HISTORY_FILE"
}

_record_device_interaction() {
    local mac="$1"
    local event="$2"  # connected | disconnected | paired | failed
    local name="${3:-Unknown}"

    if [[ ! -f "$BT_HISTORY_FILE" ]]; then
        echo '{"events":[],"devices":{}}' > "$BT_HISTORY_FILE"
    fi

    local updated
    updated="$(jq \
        --arg mac   "$mac" \
        --arg event "$event" \
        --arg name  "$name" \
        --arg ts    "$(date -Iseconds)" \
        '.devices[$mac] = (
            .devices[$mac] // {"mac":$mac,"name":$name,"events":[]}
        ) | .devices[$mac].events += [{
            "event":     $event,
            "timestamp": $ts
        }] | .devices[$mac].last_seen = $ts |
             .devices[$mac].name      = $name' \
        "$BT_HISTORY_FILE" 2>/dev/null)" || return 0

    echo "$updated" > "$BT_HISTORY_FILE"
    log_debug "Recorded: $event → $name ($mac)"
}

_update_battery_cache() {
    local mac="$1"
    local name="$2"
    local battery="$3"

    [[ ! -f "$BT_BATTERY_FILE" ]] && echo '{}' > "$BT_BATTERY_FILE"

    jq \
        --arg mac   "$mac" \
        --arg name  "$name" \
        --argjson b "$battery" \
        --arg ts    "$(date -Iseconds)" \
        '.[$mac] = {"name":$name,"battery":$b,"updated":$ts}' \
        "$BT_BATTERY_FILE" > "${BT_BATTERY_FILE}.tmp" && \
    mv "${BT_BATTERY_FILE}.tmp" "$BT_BATTERY_FILE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BLUETOOTH ENABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_enable() {
    local notify=true
    local auto_reconnect=true
    local scan_after=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-notify)    notify=false ;;
            --no-reconnect) auto_reconnect=false ;;
            --scan)         scan_after=true ;;
        esac
        shift
    done

    local current_state
    current_state="$(_get_bt_state)"

    if [[ "$current_state" == "on" ]]; then
        log_info "Bluetooth already enabled"
        [[ "$notify" == "true" ]] && _notify \
            "${ICON_BT_ON}  Bluetooth" \
            "Already enabled" "low" "2000"
        return 0
    fi

    log_info "Enabling Bluetooth adapter…"

    # Power on via bluetoothctl
    if ! echo -e 'power on\nquit' | bluetoothctl &>/dev/null; then
        # Try rfkill unblock as fallback
        if command -v rfkill &>/dev/null; then
            rfkill unblock bluetooth 2>/dev/null || true
            sleep 0.5
            echo -e 'power on\nquit' | bluetoothctl &>/dev/null || true
        fi
    fi

    # Verify state
    sleep 0.8
    local new_state
    new_state="$(_get_bt_state)"

    if [[ "$new_state" != "on" ]]; then
        log_error "Failed to enable Bluetooth"
        _notify_error "Failed to enable Bluetooth" \
            "Check rfkill and bluetooth service"
        return 1
    fi

    echo "on" > "$BT_STATE_FILE"
    _record_event "bt_on" "{}"
    _signal_waybar

    # Count previously connected devices
    local connected_count=0
    local paired_devices
    paired_devices="$(_get_paired_devices)"
    connected_count="$(echo "$paired_devices" | \
        jq '[.[] | select(.connected)] | length' 2>/dev/null || echo 0)"

    [[ "$notify" == "true" ]] && _notify_bt_on "$connected_count"

    # Auto-reconnect last devices
    if [[ "$auto_reconnect" == "true" ]]; then
        _auto_reconnect_devices &
        disown 2>/dev/null || true
    fi

    # Start scan after enable
    if [[ "$scan_after" == "true" ]]; then
        _bt_scan_start &
        disown 2>/dev/null || true
    fi

    # Run hook
    local hook="${CONFIG_DIR}/hooks/on-bluetooth-enable.sh"
    [[ -f "$hook" && -x "$hook" ]] && "$hook" & true

    log_success "Bluetooth enabled"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BLUETOOTH DISABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_disable() {
    local notify=true
    local save_state=true

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --no-notify)   notify=false ;;
            --no-save)     save_state=false ;;
        esac
        shift
    done

    local current_state
    current_state="$(_get_bt_state)"

    if [[ "$current_state" == "off" ]]; then
        log_info "Bluetooth already disabled"
        return 0
    fi

    log_info "Disabling Bluetooth adapter…"

    # Save connected device names for notification
    local connected_names=()
    local conn_devices
    conn_devices="$(_get_connected_devices)"
    while IFS= read -r name; do
        [[ -n "$name" ]] && connected_names+=("$name")
    done < <(echo "$conn_devices" | jq -r '.[].name' 2>/dev/null)

    # Stop scan if running
    _bt_scan_stop

    # Save reconnect list
    if [[ "$save_state" == "true" ]] && \
       (( ${#connected_names[@]} > 0 )); then
        echo "$conn_devices" | jq '{
            "saved_at": now | todate,
            "devices":  .
        }' > "$BT_RECONNECT_FILE" 2>/dev/null || true
    fi

    # Power off
    echo -e 'power off\nquit' | bluetoothctl &>/dev/null || true

    sleep 0.5
    echo "off" > "$BT_STATE_FILE"
    _record_event "bt_off" \
        "{\"disconnected\": $(echo "$conn_devices" | jq 'map(.name)' 2>/dev/null || echo '[]')}"
    _signal_waybar

    local was_connected=""
    (( ${#connected_names[@]} > 0 )) && \
        was_connected="${connected_names[*]}"

    [[ "$notify" == "true" ]] && _notify_bt_off "$was_connected"

    # Run hook
    local hook="${CONFIG_DIR}/hooks/on-bluetooth-disable.sh"
    [[ -f "$hook" && -x "$hook" ]] && "$hook" & true

    log_success "Bluetooth disabled"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEVICE CONNECT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_connect() {
    local mac="$1"
    local notify=true
    local attempt="${2:-1}"

    [[ -z "$mac" ]] && {
        log_error "MAC address required"
        return 1
    }

    # Normalize MAC
    mac="$(echo "$mac" | tr '[:lower:]' '[:upper:]')"

    # Get device name
    local name
    name="$(bluetoothctl info "$mac" 2>/dev/null \
        | grep '^\s*Name:' \
        | awk '{$1=""; print $0}' \
        | xargs || echo "$mac")"

    log_info "Connecting to: $name ($mac) [attempt $attempt]"

    _notify \
        "${ICON_BT_PAIRING}  Connecting…" \
        "$name" \
        "low" "2500"

    # Connect with timeout
    local connect_result
    connect_result="$(timeout "$CONNECT_TIMEOUT" \
        bluetoothctl connect "$mac" 2>&1)" || true

    if echo "$connect_result" | grep -q "Connection successful"; then
        log_success "Connected: $name ($mac)"

        # Gather device info
        sleep 1
        local device_type battery codec
        device_type="$(_detect_device_type "$mac")"
        battery="$(_get_device_battery "$mac")"
        codec="$(_get_audio_codec "$mac")"

        _record_device_interaction "$mac" "connected" "$name"
        _update_battery_cache "$mac" "$name" "$battery"
        _signal_waybar
        _notify_connected "$name" "$mac" "$device_type" "$battery" "$codec"

        # Battery warnings
        if (( battery > 0 && battery <= 10 )); then
            _notify_battery_critical "$name" "$battery"
        elif (( battery > 0 && battery <= 20 )); then
            _notify_battery_low "$name" "$battery"
        fi

        # A2DP auto-switch
        _auto_switch_audio_profile "$mac" "$device_type"

        # Run hook
        local hook="${CONFIG_DIR}/hooks/on-bluetooth-connect.sh"
        [[ -f "$hook" && -x "$hook" ]] && \
            BT_MAC="$mac" BT_NAME="$name" \
            BT_TYPE="$device_type" BT_BATTERY="$battery" \
            "$hook" & true

        return 0
    else
        log_error "Failed to connect: $name ($mac)"
        log_debug "Output: $connect_result"
        _record_device_interaction "$mac" "connect_failed" "$name"

        # Retry if not max attempts
        if (( attempt < MAX_RECONNECT_ATTEMPTS )); then
            log_info "Retrying in ${RECONNECT_DELAY}s… (${attempt}/${MAX_RECONNECT_ATTEMPTS})"
            sleep "$RECONNECT_DELAY"
            _bt_connect "$mac" "$notify" $(( attempt + 1 ))
            return $?
        fi

        _notify_error "Connection Failed" "$name"
        return 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEVICE DISCONNECT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_disconnect() {
    local mac="$1"
    local reason="${2:-}"

    [[ -z "$mac" ]] && {
        log_error "MAC address required"
        return 1
    }

    mac="$(echo "$mac" | tr '[:lower:]' '[:upper:]')"

    local name
    name="$(bluetoothctl info "$mac" 2>/dev/null \
        | grep '^\s*Name:' \
        | awk '{$1=""; print $0}' \
        | xargs || echo "$mac")"

    log_info "Disconnecting: $name ($mac)"

    bluetoothctl disconnect "$mac" &>/dev/null || true

    _record_device_interaction "$mac" "disconnected" "$name"
    _signal_waybar
    _notify_disconnected "$name" "$reason"

    log_success "Disconnected: $name"
}

_bt_disconnect_all() {
    log_info "Disconnecting all devices…"

    local connected
    connected="$(_get_connected_devices)"

    local count=0
    while IFS= read -r mac; do
        [[ -z "$mac" ]] && continue
        bluetoothctl disconnect "$mac" &>/dev/null || true
        (( count++ )) || true
    done < <(echo "$connected" | jq -r '.[].mac' 2>/dev/null)

    _signal_waybar
    log_success "Disconnected $count devices"
    _notify \
        "${ICON_BT_OFF}  All Disconnected" \
        "$count device(s) disconnected" \
        "low" "3000"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEVICE PAIRING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_pair() {
    local mac="$1"

    [[ -z "$mac" ]] && {
        log_error "MAC address required for pairing"
        return 1
    }

    mac="$(echo "$mac" | tr '[:lower:]' '[:upper:]')"

    local name
    name="$(bluetoothctl info "$mac" 2>/dev/null \
        | grep '^\s*Name:' \
        | awk '{$1=""; print $0}' \
        | xargs || echo "$mac")"

    log_info "Pairing with: $name ($mac)"

    _notify \
        "${ICON_BT_PAIRING}  Pairing…" \
        "Attempting to pair with $name" \
        "low" "3000"

    echo "pairing:$mac" > "$BT_PAIR_STATE_FILE"

    local pair_result
    pair_result="$(timeout "$PAIR_TIMEOUT" \
        bluetoothctl pair "$mac" 2>&1)" || true

    rm -f "$BT_PAIR_STATE_FILE"

    if echo "$pair_result" | grep -qiE 'Pairing successful|already paired'; then
        log_success "Paired: $name ($mac)"

        # Auto-trust after pairing
        bluetoothctl trust "$mac" &>/dev/null || true
        _record_device_interaction "$mac" "paired" "$name"
        _notify_paired "$name" "$mac"

        # Auto-connect
        sleep 0.5
        _bt_connect "$mac"
        return 0
    else
        log_error "Pairing failed: $name ($mac)"
        log_debug "Output: $pair_result"
        _record_device_interaction "$mac" "pair_failed" "$name"
        _notify_error "Pairing Failed" "$name"
        return 1
    fi
}

_bt_unpair() {
    local mac="$1"

    [[ -z "$mac" ]] && { log_error "MAC required"; return 1; }
    mac="$(echo "$mac" | tr '[:lower:]' '[:upper:]')"

    local name
    name="$(bluetoothctl info "$mac" 2>/dev/null \
        | grep '^\s*Name:' \
        | awk '{$1=""; print $0}' \
        | xargs || echo "$mac")"

    # Disconnect first
    bluetoothctl disconnect "$mac" &>/dev/null || true
    sleep 0.3
    bluetoothctl remove "$mac" &>/dev/null

    _record_device_interaction "$mac" "unpaired" "$name"
    _signal_waybar

    _notify \
        "${ICON_BT_OFF}  Device Removed" \
        "$name unpaired and forgotten" \
        "low" "3000"

    log_success "Unpaired: $name ($mac)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SCANNING ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_scan_start() {
    local duration="${1:-$SCAN_TIMEOUT}"

    # Check if already scanning
    if [[ -f "$BT_SCAN_PID_FILE" ]]; then
        local pid
        pid="$(cat "$BT_SCAN_PID_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log_info "Scan already running (PID=$pid)"
            return 0
        fi
    fi

    log_info "Starting BT scan (${duration}s)…"

    echo -e 'scan on\nquit' | bluetoothctl &>/dev/null

    _notify \
        "${ICON_BT_SCANNING}  Scanning…" \
        "Scanning for devices (${duration}s)" \
        "low" "3000"

    # Auto-stop timer
    (
        sleep "$duration"
        echo -e 'scan off\nquit' | bluetoothctl &>/dev/null
        rm -f "$BT_SCAN_PID_FILE"
        log_debug "Scan auto-stopped after ${duration}s"
    ) &

    echo "$!" > "$BT_SCAN_PID_FILE"
    log_debug "Scan started (stop PID=$!)"
}

_bt_scan_stop() {
    echo -e 'scan off\nquit' | bluetoothctl &>/dev/null || true

    if [[ -f "$BT_SCAN_PID_FILE" ]]; then
        local pid
        pid="$(cat "$BT_SCAN_PID_FILE" 2>/dev/null || echo '')"
        [[ -n "$pid" ]] && kill "$pid" 2>/dev/null || true
        rm -f "$BT_SCAN_PID_FILE"
    fi

    log_debug "Scan stopped"
}

_bt_scan_results() {
    local format="${1:-table}"
    local filter="${2:-}"

    local devices
    devices="$(_get_nearby_devices)"

    [[ -n "$filter" ]] && \
        devices="$(echo "$devices" | jq \
            --arg f "$filter" \
            '[.[] | select(.name | ascii_downcase | contains($f | ascii_downcase))]' \
            2>/dev/null)"

    case "$format" in
        json)
            echo "$devices"
            ;;

        table|human|*)
            local count
            count="$(echo "$devices" | jq 'length' 2>/dev/null || echo 0)"

            echo -e ""
            echo -e "${CLR_BOLD}${CLR_BRIGHT_BLUE}${ICON_BT_SCANNING}  Bluetooth Devices (${count})${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            printf "${CLR_BOLD}%-4s %-24s %-18s %-12s %-8s %-6s${CLR_RESET}\n" \
                "" "NAME" "MAC" "TYPE" "STATUS" "BATT"

            echo -e "${CLR_GRAY}─────────────────────────────────────────────────────────${CLR_RESET}"

            echo "$devices" | jq -r '.[] |
                [.icon, .name, .mac, .type,
                 (if .connected then "connected" elif .paired then "paired" else "" end),
                 (if .battery > 0 then (.battery|tostring)+"%" else "" end)] |
                @tsv' 2>/dev/null | \
            while IFS=$'\t' read -r icon name mac type status batt; do
                local color="$CLR_RESET"
                local status_color="$CLR_GRAY"

                case "$status" in
                    connected)
                        color="$CLR_GREEN"
                        status_color="${CLR_GREEN}${CLR_BOLD}"
                        ;;
                    paired)
                        color="$CLR_BLUE"
                        status_color="$CLR_BLUE"
                        ;;
                esac

                printf "${color}%-4s %-24s %-18s %-12s ${status_color}%-8s${CLR_RESET}" \
                    "$icon" \
                    "$(echo "$name" | cut -c1-22)" \
                    "$mac" \
                    "$(echo "$type" | cut -c1-10)" \
                    "$status"

                if [[ -n "$batt" ]]; then
                    local batt_num="${batt/\%/}"
                    local batt_color
                    batt_color="$(_battery_color "$batt_num")"
                    local batt_icon
                    batt_icon="$(_battery_icon "$batt_num")"
                    printf " ${batt_color}${batt_icon} %s${CLR_RESET}" "$batt"
                fi
                echo ""
            done

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AUDIO PROFILE MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_audio_codec() {
    local mac="$1"
    local mac_clean
    mac_clean="${mac//:/}"

    if command -v pactl &>/dev/null; then
        local card
        card="$(pactl list cards 2>/dev/null \
            | grep -A5 "${mac_clean}" \
            | grep 'active profile' \
            | awk -F: '{print $2}' \
            | xargs)"

        case "${card:-}" in
            *a2dp*)    echo "A2DP"  ;;
            *hfp*|*hsp*) echo "HFP" ;;
            *le-audio*) echo "LE"   ;;
            *)          echo ""     ;;
        esac
    fi
}

_get_card_name() {
    local mac="$1"
    local mac_clean="${mac//:/}"

    pactl list cards short 2>/dev/null \
        | grep -i "$mac_clean" \
        | awk '{print $2}' \
        | head -1 || echo ''
}

_set_audio_profile() {
    local mac="$1"
    local profile="$2"  # a2dp | hfp | hfp-msbc | le-audio | off

    command -v pactl &>/dev/null || {
        log_warn "pactl not available — cannot switch audio profile"
        return 1
    }

    local card
    card="$(_get_card_name "$mac")"

    [[ -z "$card" ]] && {
        log_error "No PulseAudio card for $mac"
        return 1
    }

    local profile_id
    case "$profile" in
        a2dp|a2dp-sink)  profile_id="a2dp-sink"               ;;
        hfp|handsfree)   profile_id="headset-head-unit"        ;;
        hfp-msbc|msbc)   profile_id="headset-head-unit-msbc"   ;;
        le-audio|lc3)    profile_id="le-audio-stereo"          ;;
        off)             profile_id="off"                       ;;
        *)               profile_id="$profile"                  ;;
    esac

    log_info "Setting audio profile: $profile_id on $card"

    if pactl set-card-profile "$card" "$profile_id" 2>/dev/null; then
        local dev_name
        dev_name="$(bluetoothctl info "$mac" 2>/dev/null \
            | grep '^\s*Name:' \
            | awk '{$1=""; print $0}' \
            | xargs || echo "$mac")"

        _notify_profile_changed "$dev_name" "$profile_id"
        log_success "Profile set: $profile_id"
        return 0
    else
        log_error "Failed to set profile: $profile_id"
        return 1
    fi
}

_auto_switch_audio_profile() {
    local mac="$1"
    local device_type="${2:-}"

    case "$device_type" in
        headphones|earbuds|speakers|audio)
            # Prefer A2DP for audio-only devices
            sleep 1
            _set_audio_profile "$mac" "a2dp" &>/dev/null & true
            log_debug "Auto-switched to A2DP for $device_type"
            ;;
        headset)
            # Keep HFP for headsets (they have mics)
            log_debug "Keeping HFP for headset"
            ;;
    esac
}

_list_audio_profiles() {
    local mac="$1"
    local card
    card="$(_get_card_name "$mac")"

    [[ -z "$card" ]] && return 1

    log_info "Available profiles for card: $card"

    pactl list cards 2>/dev/null \
        | awk "/bluez_card.*${card//./\\.}/,/^Card/" \
        | grep -A200 'Profiles:' \
        | grep '^\s\+[a-z]' \
        | awk '{print $1}' \
        | tr -d ':' || echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# AUTO-RECONNECT ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_auto_reconnect_devices() {
    [[ ! -f "$BT_RECONNECT_FILE" ]] && return 0

    local saved_devices
    saved_devices="$(jq '.devices // []' "$BT_RECONNECT_FILE" 2>/dev/null \
        || echo '[]')"

    local count
    count="$(echo "$saved_devices" | jq 'length' 2>/dev/null || echo 0)"

    (( count == 0 )) && return 0

    log_info "Auto-reconnecting $count saved device(s)…"

    sleep 2  # Wait for adapter to be ready

    echo "$saved_devices" | jq -r '.[] | select(.paired == true) | .mac' \
        2>/dev/null | \
    while IFS= read -r mac; do
        [[ -z "$mac" ]] && continue
        log_debug "Auto-reconnect attempt: $mac"
        _bt_connect "$mac" --no-retry &>/dev/null || true
        sleep 1
    done

    rm -f "$BT_RECONNECT_FILE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TRUST / BLOCK MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_trust() {
    local mac="$1"
    [[ -z "$mac" ]] && return 1

    bluetoothctl trust "$mac" &>/dev/null && {
        log_success "Trusted: $mac"
        _notify "${ICON_TRUST}  Device Trusted" \
            "$mac will auto-connect" "low" "3000"
    }
}

_bt_untrust() {
    local mac="$1"
    [[ -z "$mac" ]] && return 1

    bluetoothctl untrust "$mac" &>/dev/null && {
        log_success "Untrusted: $mac"
        _notify "${ICON_TRUST}  Device Untrusted" \
            "$mac" "low" "3000"
    }
}

_bt_block() {
    local mac="$1"
    [[ -z "$mac" ]] && return 1

    bluetoothctl block "$mac" &>/dev/null && {
        log_success "Blocked: $mac"
        _notify "${ICON_BLOCK}  Device Blocked" \
            "$mac has been blocked" "normal" "4000"
    }
}

_bt_unblock() {
    local mac="$1"
    [[ -z "$mac" ]] && return 1

    bluetoothctl unblock "$mac" &>/dev/null && {
        log_success "Unblocked: $mac"
    }
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DISCOVERABLE MODE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_discoverable() {
    local state="${1:-toggle}"
    local timeout="${2:-120}"

    local current
    current="$(_get_discoverable_state)"

    local target
    case "$state" in
        on|enable)   target="on"  ;;
        off|disable) target="off" ;;
        toggle)
            [[ "$current" == "yes" ]] && target="off" || target="on"
            ;;
    esac

    echo -e "discoverable $target\nquit" | bluetoothctl &>/dev/null

    if [[ "$target" == "on" ]]; then
        echo -e "discoverable-timeout $timeout\nquit" \
            | bluetoothctl &>/dev/null

        _notify \
            "${ICON_BT_ON}  Discoverable" \
            "Device visible for ${timeout}s" \
            "low" "5000"

        log_info "Discoverable ON for ${timeout}s"

        # Auto-disable after timeout
        (
            sleep "$timeout"
            echo -e 'discoverable off\nquit' | bluetoothctl &>/dev/null
            _signal_waybar
            log_debug "Discoverable auto-disabled"
        ) &
        disown 2>/dev/null || true
    else
        _notify \
            "${ICON_BT_OFF}  Not Discoverable" \
            "Device hidden from scan" \
            "low" "3000"
        log_info "Discoverable OFF"
    fi

    _signal_waybar
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BATTERY MONITOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_bt_check_all_batteries() {
    local connected
    connected="$(_get_connected_devices)"

    echo "$connected" | jq -r '.[] | [.mac, .name, (.battery|tostring)] | @tsv' \
        2>/dev/null | \
    while IFS=$'\t' read -r mac name batt; do
        [[ -z "$mac" ]] && continue
        (( batt == 0 )) && continue  # No battery data

        _update_battery_cache "$mac" "$name" "$batt"

        if (( batt <= 5 )); then
            _notify_battery_critical "$name" "$batt"
        elif (( batt <= 15 )); then
            _notify_battery_low "$name" "$batt"
        fi

        log_debug "Battery: $name = $batt%"
    done
}

_bt_battery_report() {
    local format="${1:-human}"

    local connected
    connected="$(_get_connected_devices)"

    case "$format" in
        json)
            echo "$connected" | jq \
                '[.[] | {mac: .mac, name: .name, battery: .battery, icon: .icon}]' \
                2>/dev/null
            ;;
        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_BRIGHT_BLUE}  Battery Report${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            local any=false
            echo "$connected" | jq -r \
                '.[] | select(.battery > 0) | [.icon, .name, (.battery|tostring)] | @tsv' \
                2>/dev/null | \
            while IFS=$'\t' read -r icon name batt; do
                any=true
                local batt_icon
                batt_icon="$(_battery_icon "$batt")"
                local batt_color
                batt_color="$(_battery_color "$batt")"

                printf "  ${CLR_WHITE}%-4s %-24s${CLR_RESET} ${batt_color}%s %s%%${CLR_RESET}\n" \
                    "$icon" "$(echo "$name" | cut -c1-22)" \
                    "$batt_icon" "$batt"
            done

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATUS DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_status() {
    local format="${1:-human}"

    local bt_state adapter adapter_name
    bt_state="$(_get_bt_state)"
    adapter="$(_get_adapter)"
    adapter_name="$(_get_adapter_name)"

    local discovering discoverable pairable
    discovering="$(_get_discovering_state)"
    discoverable="$(_get_discoverable_state)"
    pairable="$(_get_pairable_state)"

    local connected_devices paired_devices
    connected_devices="$(_get_connected_devices)"
    paired_devices="$(_get_paired_devices)"

    local connected_count paired_count
    connected_count="$(echo "$connected_devices" | \
        jq 'length' 2>/dev/null || echo 0)"
    paired_count="$(echo "$paired_devices" | \
        jq 'length' 2>/dev/null || echo 0)"

    case "$format" in
        json)
            jq -n \
                --arg  state       "$bt_state" \
                --arg  adapter     "$adapter" \
                --arg  name        "$adapter_name" \
                --argjson enabled  "$([ "$bt_state" = "on" ] && \
                                     echo true || echo false)" \
                --argjson scan     "$([ "$discovering" = "yes" ] && \
                                     echo true || echo false)" \
                --argjson disc     "$([ "$discoverable" = "yes" ] && \
                                     echo true || echo false)" \
                --argjson pair_on  "$([ "$pairable"    = "yes" ] && \
                                     echo true || echo false)" \
                --argjson conn_cnt "$connected_count" \
                --argjson pair_cnt "$paired_count" \
                --argjson conn_dev "$connected_devices" \
                '{
                    "enabled":           $enabled,
                    "state":             $state,
                    "adapter":           $adapter,
                    "adapter_name":      $name,
                    "scanning":          $scan,
                    "discoverable":      $disc,
                    "pairable":          $pair_on,
                    "connected_count":   $conn_cnt,
                    "paired_count":      $pair_cnt,
                    "connected_devices": $conn_dev
                }'
            ;;

        waybar)
            local text tooltip class

            if [[ "$bt_state" == "off" ]]; then
                text="${ICON_BT_OFF}"
                tooltip="Bluetooth disabled"
                class="bt-off"
            elif (( connected_count > 0 )); then
                local first_name
                first_name="$(echo "$connected_devices" | \
                    jq -r '.[0].name // "Device"' 2>/dev/null)"
                local first_icon
                first_icon="$(echo "$connected_devices" | \
                    jq -r '.[0].icon // "󰂱"' 2>/dev/null)"
                local first_batt
                first_batt="$(echo "$connected_devices" | \
                    jq -r '.[0].battery // 0' 2>/dev/null)"

                if (( connected_count == 1 )); then
                    text="${first_icon}  ${first_name}"
                else
                    text="${ICON_BT_CONNECTED}  ${connected_count}"
                fi

                tooltip="${ICON_BT_CONNECTED}  $connected_count connected"
                (( first_batt > 0 )) && \
                    tooltip+="  •  $(_battery_icon "$first_batt") ${first_batt}%"
                class="bt-connected"
            else
                text="${ICON_BT_ON}"
                tooltip="Bluetooth on — no devices"
                class="bt-idle"
            fi

            [[ "$discovering" == "yes" ]] && class+=" bt-scanning"

            jq -n \
                --arg text    "$text" \
                --arg tooltip "$tooltip" \
                --arg class   "$class" \
                '{"text":$text,"tooltip":$tooltip,"class":$class}'
            ;;

        short)
            if [[ "$bt_state" == "off" ]]; then
                echo "${ICON_BT_OFF}  Off"
            elif (( connected_count > 0 )); then
                local first
                first="$(echo "$connected_devices" | \
                    jq -r '.[0].name // "Device"' 2>/dev/null)"
                echo "${ICON_BT_CONNECTED}  ${first}"
            else
                echo "${ICON_BT_ON}  On"
            fi
            ;;

        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_BRIGHT_BLUE}${ICON_ASH} ASH Bluetooth Status${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            if [[ "$bt_state" == "on" ]]; then
                echo -e "  Adapter  : ${CLR_GREEN}${CLR_BOLD}${ICON_BT_ON}  Enabled${CLR_RESET}"
            else
                echo -e "  Adapter  : ${CLR_GRAY}${ICON_BT_OFF}  Disabled${CLR_RESET}"
            fi

            [[ -n "$adapter_name" ]] && \
                echo -e "  Name     : ${CLR_WHITE}${adapter_name}${CLR_RESET}"
            [[ -n "$adapter" ]] && \
                echo -e "  MAC      : ${CLR_GRAY}${adapter}${CLR_RESET}"

            echo -e "  Scanning : ${CLR_CYAN}$(
                [[ "$discovering" == "yes" ]] \
                && echo "${CLR_YELLOW}Active${CLR_RESET}" \
                || echo "${CLR_GRAY}Off${CLR_RESET}"
            )"

            echo -e "  Visible  : ${CLR_CYAN}$(
                [[ "$discoverable" == "yes" ]] \
                && echo "${CLR_GREEN}Yes${CLR_RESET}" \
                || echo "${CLR_GRAY}No${CLR_RESET}"
            )"

            echo -e ""
            echo -e "  ${CLR_BOLD}Connected${CLR_RESET} (${connected_count})"

            echo "$connected_devices" | \
                jq -r '.[] | [.icon, .name, (.battery|tostring), .type] | @tsv' \
                2>/dev/null | \
            while IFS=$'\t' read -r icon name batt type; do
                local batt_str=""
                if (( batt > 0 )); then
                    local bi bc
                    bi="$(_battery_icon "$batt")"
                    bc="$(_battery_color "$batt")"
                    batt_str="  ${bc}${bi} ${batt}%${CLR_RESET}"
                fi
                echo -e "    ${CLR_GREEN}${icon}  ${name}${CLR_RESET}${batt_str}  ${CLR_GRAY}${type}${CLR_RESET}"
            done

            echo -e ""
            echo -e "  ${CLR_BOLD}Paired${CLR_RESET} (${paired_count})"
            echo "$paired_devices" | \
                jq -r '.[] | select(.connected == false) | [.icon, .name] | @tsv' \
                2>/dev/null | \
            while IFS=$'\t' read -r icon name; do
                echo -e "    ${CLR_GRAY}${icon}  ${name}${CLR_RESET}"
            done

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_BRIGHT_BLUE}${ICON_ASH} ASH Bluetooth v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [COMMAND] [OPTIONS]

${CLR_BOLD}POWER${CLR_RESET}
  ${CLR_GREEN}(no args)${CLR_RESET}              Toggle on/off
  ${CLR_GREEN}--on${CLR_RESET}                   Enable adapter
  ${CLR_GREEN}--off${CLR_RESET}                  Disable adapter
  ${CLR_GREEN}--toggle${CLR_RESET}               Toggle state

${CLR_BOLD}CONNECTIONS${CLR_RESET}
  ${CLR_YELLOW}--connect MAC${CLR_RESET}          Connect to device
  ${CLR_YELLOW}--disconnect MAC${CLR_RESET}       Disconnect device
  ${CLR_YELLOW}--disconnect-all${CLR_RESET}       Disconnect all
  ${CLR_YELLOW}--pair MAC${CLR_RESET}             Pair with device
  ${CLR_YELLOW}--unpair MAC${CLR_RESET}           Remove paired device

${CLR_BOLD}SCANNING${CLR_RESET}
  ${CLR_CYAN}--scan${CLR_RESET}                 Start scan (30s)
  ${CLR_CYAN}--scan-stop${CLR_RESET}            Stop scan
  ${CLR_CYAN}--list${CLR_RESET}                 List all devices (table)
  ${CLR_CYAN}--list-json${CLR_RESET}            List as JSON
  ${CLR_CYAN}--connected${CLR_RESET}            List connected devices

${CLR_BOLD}AUDIO${CLR_RESET}
  ${CLR_MAGENTA}--profile MAC a2dp${CLR_RESET}     Set A2DP profile
  ${CLR_MAGENTA}--profile MAC hfp${CLR_RESET}      Set HFP profile
  ${CLR_MAGENTA}--profile MAC msbc${CLR_RESET}     Set mSBC profile
  ${CLR_MAGENTA}--profile MAC le${CLR_RESET}       Set LE Audio profile
  ${CLR_MAGENTA}--profiles MAC${CLR_RESET}         List available profiles

${CLR_BOLD}TRUST & VISIBILITY${CLR_RESET}
  ${CLR_WHITE}--trust MAC${CLR_RESET}            Trust device
  ${CLR_WHITE}--untrust MAC${CLR_RESET}          Remove trust
  ${CLR_WHITE}--block MAC${CLR_RESET}            Block device
  ${CLR_WHITE}--discoverable${CLR_RESET}         Make visible (120s)
  ${CLR_WHITE}--discoverable off${CLR_RESET}     Hide device
  ${CLR_WHITE}--discoverable 300${CLR_RESET}     Visible for 300s

${CLR_BOLD}STATUS & BATTERY${CLR_RESET}
  ${CLR_WHITE}--status${CLR_RESET}               Human status
  ${CLR_WHITE}--status=json${CLR_RESET}          JSON status
  ${CLR_WHITE}--status=waybar${CLR_RESET}        Waybar JSON
  ${CLR_WHITE}--status=short${CLR_RESET}         Compact status
  ${CLR_WHITE}--battery${CLR_RESET}              Battery report
  ${CLR_WHITE}--battery=json${CLR_RESET}         Battery JSON
  ${CLR_WHITE}--battery-check${CLR_RESET}        Check & notify low
  ${CLR_WHITE}--version${CLR_RESET}              Show version
  ${CLR_WHITE}--help${CLR_RESET}                 Show help

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    _ensure_dirs
    _check_deps
    _acquire_lock || { log_error "Lock failed"; exit 1; }

    case "${1:-}" in
        # ── Power ─────────────────────────────────────────────────────────
        ""| --toggle|-t)
            local s; s="$(_get_bt_state)"
            [[ "$s" == "on" ]] && _bt_disable || _bt_enable
            ;;
        --on|on|enable)   shift; _bt_enable  "$@" ;;
        --off|off|disable) shift; _bt_disable "$@" ;;

        # ── Connect ───────────────────────────────────────────────────────
        --connect|-c)
            shift
            [[ -z "${1:-}" ]] && { log_error "MAC required"; exit 1; }
            _bt_connect "$1"
            ;;
        --disconnect|-d)
            shift
            [[ -z "${1:-}" ]] && { log_error "MAC required"; exit 1; }
            _bt_disconnect "$1"
            ;;
        --disconnect-all)
            _bt_disconnect_all
            ;;

        # ── Pairing ───────────────────────────────────────────────────────
        --pair|-p)
            shift
            [[ -z "${1:-}" ]] && { log_error "MAC required"; exit 1; }
            _bt_pair "$1"
            ;;
        --unpair|--remove)
            shift
            [[ -z "${1:-}" ]] && { log_error "MAC required"; exit 1; }
            _bt_unpair "$1"
            ;;

        # ── Scanning ──────────────────────────────────────────────────────
        --scan|--scan-start)
            shift; _bt_scan_start "${1:-30}"
            ;;
        --scan-stop)      _bt_scan_stop ;;
        --list|--devices) _bt_scan_results table ;;
        --list-json)      _bt_scan_results json  ;;
        --connected)
            _get_connected_devices | \
                jq -r '.[] | "\(.icon)  \(.name)  [\(.mac)]"' 2>/dev/null
            ;;
        --paired)
            _get_paired_devices | \
                jq -r '.[] | "\(.icon)  \(.name)  [\(.mac)]"' 2>/dev/null
            ;;

        # ── Audio ─────────────────────────────────────────────────────────
        --profile)
            shift
            local mac="${1:-}"; shift
            local profile="${1:-a2dp}"
            [[ -z "$mac" ]] && { log_error "MAC required"; exit 1; }
            _set_audio_profile "$mac" "$profile"
            ;;
        --profiles)
            shift; _list_audio_profiles "${1:-}"
            ;;

        # ── Trust & Visibility ────────────────────────────────────────────
        --trust)
            shift; _bt_trust "$1"
            ;;
        --untrust)
            shift; _bt_untrust "$1"
            ;;
        --block)
            shift; _bt_block "$1"
            ;;
        --unblock)
            shift; _bt_unblock "$1"
            ;;
        --discoverable)
            shift
            local disc_state="${1:-toggle}"
            local disc_time="${2:-120}"
            if [[ "$disc_state" =~ ^[0-9]+$ ]]; then
                _bt_discoverable "on" "$disc_state"
            else
                _bt_discoverable "$disc_state" "$disc_time"
            fi
            ;;

        # ── Battery ───────────────────────────────────────────────────────
        --battery)        _bt_battery_report human ;;
        --battery=json)   _bt_battery_report json  ;;
        --battery-check)  _bt_check_all_batteries  ;;

        # ── Status ────────────────────────────────────────────────────────
        --status|-s)      _show_status human   ;;
        --status=json)    _show_status json    ;;
        --status=waybar)  _show_status waybar  ;;
        --status=short)   _show_status short   ;;
        --status=*)       _show_status "${1#--status=}" ;;

        # ── Misc ─────────────────────────────────────────────────────────
        --version)
            echo "$SCRIPT_NAME v$SCRIPT_VERSION"
            ;;
        --help|-h|help)
            _show_help
            ;;
        *)
            log_error "Unknown command: ${1}"
            _show_help
            exit 1
            ;;
    esac

    exit 0
}

main "$@"