#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HyprIdle Ultra Suspend Script                    ║
# ║  Premium system suspend controller with pre-suspend checklist, safe          ║
# ║  process termination, network teardown, peripheral handoff, battery          ║
# ║  threshold protection, wake-source management, and resume orchestration      ║
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

readonly SCRIPT_NAME="ash-suspend"
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG paths
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"

# State files
readonly SUSPEND_STATE_FILE="${RUNTIME_DIR}/suspend.state"
readonly SUSPEND_LOCK_FILE="${RUNTIME_DIR}/suspend.lock"
readonly SUSPEND_LOG_FILE="${CACHE_DIR}/logs/suspend.log"
readonly SUSPEND_HISTORY_FILE="${DATA_DIR}/suspend-history.json"
readonly SUSPEND_STATS_FILE="${CACHE_DIR}/suspend-stats.json"
readonly SUSPEND_INHIBIT_FILE="${RUNTIME_DIR}/suspend-inhibit"
readonly SUSPEND_PROFILE_FILE="${CONFIG_DIR}/suspend-profile.json"
readonly SUSPEND_PRE_STATE_FILE="${RUNTIME_DIR}/suspend-pre-state.json"
readonly SUSPEND_NETWORK_STATE="${RUNTIME_DIR}/suspend-network.json"
readonly SUSPEND_MEDIA_STATE="${RUNTIME_DIR}/suspend-media.json"
readonly SUSPEND_TIMESTAMP_FILE="${RUNTIME_DIR}/suspend-timestamp"
readonly SUSPEND_REASON_FILE="${RUNTIME_DIR}/suspend-reason"
readonly BATTERY_STATE_FILE="/sys/class/power_supply/BAT0"

# Sound files
readonly SOUND_SUSPEND="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/shutdown.ogg"
readonly SOUND_RESUME="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/startup.ogg"
readonly SOUND_BLOCKED="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/warning.ogg"
readonly SOUND_CRITICAL="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/error.ogg"

# Icons
readonly ICON_SLEEP="󰒲"
readonly ICON_WAKE="󰖙"
readonly ICON_BATTERY="󰁹"
readonly ICON_BATTERY_CRIT="󰂎"
readonly ICON_NETWORK="󰤨"
readonly ICON_BLUETOOTH="󰂯"
readonly ICON_SHIELD="󰡗"
readonly ICON_MEDIA="󰝚"
readonly ICON_WARNING="󰀦"
readonly ICON_BLOCK="󱏔"
readonly ICON_TIMER="󱑃"
readonly ICON_ASH="󱎫"
readonly ICON_SYNC="󰑓"
readonly ICON_SAVE="󰆓"
readonly ICON_DOCKER="󰡨"
readonly ICON_VPN="󰌾"
readonly ICON_CLOUD="󰅣"
readonly ICON_CHECK="󰄬"
readonly ICON_LAPTOP="󰍹"

# ANSI colors
readonly CLR_RESET='\033[0m'
readonly CLR_BOLD='\033[1m'
readonly CLR_RED='\033[0;31m'
readonly CLR_GREEN='\033[0;32m'
readonly CLR_YELLOW='\033[0;33m'
readonly CLR_BLUE='\033[0;34m'
readonly CLR_MAGENTA='\033[0;35m'
readonly CLR_CYAN='\033[0;36m'
readonly CLR_WHITE='\033[0;37m'
readonly CLR_GRAY='\033[0;90m'

# Suspend modes
readonly MODE_SUSPEND="suspend"
readonly MODE_HIBERNATE="hibernate"
readonly MODE_HYBRID="hybrid-sleep"
readonly MODE_SUSPEND_THEN_HIBERNATE="suspend-then-hibernate"

# Safety thresholds
readonly MIN_BATTERY_FOR_SUSPEND=10     # % below which suspend is risky
readonly MIN_BATTERY_FOR_HIBERNATE=5    # % below which hibernate only
readonly SYNC_TIMEOUT=10               # seconds to wait for sync
readonly NETWORK_TEARDOWN_TIMEOUT=5    # seconds for network to tear down
readonly TRANSFER_WARN_THRESHOLD=1000  # KB/s — warn if active transfers

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR" "$STATE_DIR" "$DATA_DIR"
        "$CONFIG_DIR" "$RUNTIME_DIR"
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

    # Rotation at 512KB
    if [[ -f "$SUSPEND_LOG_FILE" ]]; then
        local sz
        sz="$(stat -c%s "$SUSPEND_LOG_FILE" 2>/dev/null || echo 0)"
        if (( sz > 524288 )); then
            mv "$SUSPEND_LOG_FILE" \
               "${SUSPEND_LOG_FILE}.$(date +%Y%m%d_%H%M%S).old"
            find "${CACHE_DIR}/logs" \
                -name 'suspend.log.*.old' \
                -mtime +30 \
                -delete 2>/dev/null || true
        fi
    fi

    echo "$log_line" >> "$SUSPEND_LOG_FILE" 2>/dev/null || true

    [[ ! -t 2 ]] && return 0
    case "$level" in
        ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[✗]${CLR_RESET} $message"     >&2 ;;
        WARN)    echo -e "${CLR_YELLOW}[⚠]${CLR_RESET}  $message"             >&2 ;;
        INFO)    echo -e "${CLR_CYAN}[ℹ]${CLR_RESET}  $message"               >&2 ;;
        SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[✓]${CLR_RESET} $message"    >&2 ;;
        SAFETY)  echo -e "${CLR_MAGENTA}${CLR_BOLD}[⚡]${CLR_RESET} $message" >&2 ;;
        DEBUG)
            [[ "${ASH_DEBUG:-0}" == "1" ]] && \
                echo -e "${CLR_GRAY}[~] $message${CLR_RESET}" >&2 ;;
    esac
}

log_info()   { _log INFO   "$@"; }
log_warn()   { _log WARN   "$@"; }
log_error()  { _log ERROR  "$@"; }
log_success(){ _log SUCCESS "$@"; }
log_safety() { _log SAFETY "$@"; }
log_debug()  { _log DEBUG  "$@"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOCK MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_acquire_lock() {
    local max_wait="${1:-5}"
    local waited=0

    while [[ -f "$SUSPEND_LOCK_FILE" ]]; do
        local pid
        pid="$(cat "$SUSPEND_LOCK_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            log_warn "Stale suspend-lock (PID=$pid) — removing"
            rm -f "$SUSPEND_LOCK_FILE"
            break
        fi
        if (( waited >= max_wait )); then
            log_error "Could not acquire suspend-lock after ${max_wait}s"
            return 1
        fi
        sleep 0.5
        (( waited++ )) || true
    done

    echo "$$" > "$SUSPEND_LOCK_FILE"
    log_debug "Suspend-lock acquired (PID=$$)"
    return 0
}

_release_lock() {
    local pid
    pid="$(cat "$SUSPEND_LOCK_FILE" 2>/dev/null || echo '')"
    [[ "$pid" == "$$" ]] && rm -f "$SUSPEND_LOCK_FILE"
    log_debug "Suspend-lock released"
}

_cleanup() {
    _release_lock
    rm -f "${RUNTIME_DIR}/suspend-temp-$$"* 2>/dev/null || true
    log_debug "Suspend cleanup done"
}

trap '_cleanup' EXIT INT TERM HUP

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CAPABILITY DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g HAS_SYSTEMCTL=false
declare -g HAS_LOGINCTL=false
declare -g HAS_PLAYERCTL=false
declare -g HAS_PACTL=false
declare -g HAS_NMCLI=false
declare -g HAS_BLUETOOTHCTL=false
declare -g HAS_HYPRCTL=false
declare -g HAS_BRIGHTNESSCTL=false
declare -g HAS_SYNC_CMD=true
declare -g HAS_JQ=false
declare -g HAS_NOTIFY=false
declare -g HAS_UPOWER=false
declare -g HAS_ACPI=false
declare -g HAS_DOCKER=false
declare -g HAS_PODMAN=false
declare -g HAS_RESTIC=false
declare -g HAS_RCLONE=false
declare -g IS_LAPTOP=false
declare -g HAS_BATTERY=false
declare -g IS_WAYLAND=false
declare -g SUSPEND_BACKEND=""

_detect_capabilities() {
    command -v systemctl     &>/dev/null && HAS_SYSTEMCTL=true
    command -v loginctl      &>/dev/null && HAS_LOGINCTL=true
    command -v playerctl     &>/dev/null && HAS_PLAYERCTL=true
    command -v pactl         &>/dev/null && HAS_PACTL=true
    command -v nmcli         &>/dev/null && HAS_NMCLI=true
    command -v bluetoothctl  &>/dev/null && HAS_BLUETOOTHCTL=true
    command -v hyprctl       &>/dev/null && HAS_HYPRCTL=true
    command -v brightnessctl &>/dev/null && HAS_BRIGHTNESSCTL=true
    command -v jq            &>/dev/null && HAS_JQ=true
    command -v notify-send   &>/dev/null && HAS_NOTIFY=true
    command -v upower        &>/dev/null && HAS_UPOWER=true
    command -v acpi          &>/dev/null && HAS_ACPI=true
    command -v docker        &>/dev/null && HAS_DOCKER=true
    command -v podman        &>/dev/null && HAS_PODMAN=true
    command -v restic        &>/dev/null && HAS_RESTIC=true
    command -v rclone        &>/dev/null && HAS_RCLONE=true

    [[ -n "${WAYLAND_DISPLAY:-}" || \
       -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && IS_WAYLAND=true

    if [[ -d /sys/class/power_supply/BAT0 || \
          -d /sys/class/power_supply/BAT1 ]]; then
        IS_LAPTOP=true
        HAS_BATTERY=true
    fi

    # Determine suspend backend
    if [[ "$HAS_SYSTEMCTL" == "true" ]]; then
        SUSPEND_BACKEND="systemctl"
    elif [[ "$HAS_LOGINCTL" == "true" ]]; then
        SUSPEND_BACKEND="loginctl"
    elif [[ -w /sys/power/state ]]; then
        SUSPEND_BACKEND="sysfs"
    else
        SUSPEND_BACKEND="none"
    fi

    log_debug "Capabilities: backend=$SUSPEND_BACKEND laptop=$IS_LAPTOP \
docker=$HAS_DOCKER rclone=$HAS_RCLONE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PROFILE LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g CFG_MODE="suspend"
declare -g CFG_LOCK_BEFORE_SUSPEND=true
declare -g CFG_INHIBIT_CHECK=true
declare -g CFG_BATTERY_CHECK=true
declare -g CFG_MIN_BATTERY=$MIN_BATTERY_FOR_SUSPEND
declare -g CFG_SYNC_BEFORE=true
declare -g CFG_PAUSE_MEDIA=true
declare -g CFG_RESUME_MEDIA=true
declare -g CFG_DISCONNECT_BLUETOOTH=false
declare -g CFG_DISCONNECT_VPN=false
declare -g CFG_SAVE_NETWORK_STATE=true
declare -g CFG_RESTORE_NETWORK=true
declare -g CFG_STOP_DOCKER=false
declare -g CFG_WARN_TRANSFERS=true
declare -g CFG_TRANSFER_WARN_KB=$TRANSFER_WARN_THRESHOLD
declare -g CFG_GRACE_PERIOD=3
declare -g CFG_SOUND_SUSPEND=true
declare -g CFG_SOUND_RESUME=true
declare -g CFG_NOTIFY_SUSPEND=true
declare -g CFG_NOTIFY_RESUME=true
declare -g CFG_ANALYTICS=true
declare -g CFG_WAYBAR_SIGNAL=10
declare -g CFG_SAVE_SESSION=true
declare -g CFG_BACKUP_CHECK=false
declare -g CFG_CLOUD_SYNC_CHECK=false
declare -g CFG_DIM_BEFORE=true
declare -g CFG_WAKEUP_BRIGHTNESS=80
declare -g CFG_KILL_RECORDING=true
declare -g CFG_HIBERNATE_THRESHOLD=15

_load_profile() {
    [[ ! -f "$SUSPEND_PROFILE_FILE" ]] && {
        log_debug "No suspend profile — using defaults"
        return 0
    }

    [[ "$HAS_JQ" == "false" ]] && return 0

    log_debug "Loading suspend profile: $SUSPEND_PROFILE_FILE"

    local get
    get()      { jq -r ".${1} // \"${2}\"" "$SUSPEND_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_num
    get_num()  { jq -r ".${1} // ${2}"     "$SUSPEND_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_bool
    get_bool() {
        jq -r "if .${1} == true then \"true\" else \"false\" end" \
            "$SUSPEND_PROFILE_FILE" 2>/dev/null || echo "$2"
    }

    CFG_MODE="$(get              mode               'suspend')"
    CFG_LOCK_BEFORE_SUSPEND="$(get_bool lock_before true)"
    CFG_INHIBIT_CHECK="$(get_bool inhibit_check     true)"
    CFG_BATTERY_CHECK="$(get_bool battery_check     true)"
    CFG_MIN_BATTERY="$(get_num   min_battery_pct    $MIN_BATTERY_FOR_SUSPEND)"
    CFG_SYNC_BEFORE="$(get_bool  sync_before        true)"
    CFG_PAUSE_MEDIA="$(get_bool  pause_media        true)"
    CFG_RESUME_MEDIA="$(get_bool resume_media       true)"
    CFG_DISCONNECT_BLUETOOTH="$(get_bool disconnect_bluetooth false)"
    CFG_DISCONNECT_VPN="$(get_bool disconnect_vpn   false)"
    CFG_SAVE_NETWORK_STATE="$(get_bool save_network_state true)"
    CFG_RESTORE_NETWORK="$(get_bool restore_network  true)"
    CFG_STOP_DOCKER="$(get_bool  stop_docker         false)"
    CFG_WARN_TRANSFERS="$(get_bool warn_transfers    true)"
    CFG_TRANSFER_WARN_KB="$(get_num transfer_warn_kb $TRANSFER_WARN_THRESHOLD)"
    CFG_GRACE_PERIOD="$(get_num  grace_period        3)"
    CFG_SOUND_SUSPEND="$(get_bool sound_suspend      true)"
    CFG_SOUND_RESUME="$(get_bool  sound_resume       true)"
    CFG_NOTIFY_SUSPEND="$(get_bool notify_suspend    true)"
    CFG_NOTIFY_RESUME="$(get_bool  notify_resume     true)"
    CFG_ANALYTICS="$(get_bool     analytics          true)"
    CFG_WAYBAR_SIGNAL="$(get_num  waybar_signal      10)"
    CFG_SAVE_SESSION="$(get_bool  save_session       true)"
    CFG_DIM_BEFORE="$(get_bool    dim_before         true)"
    CFG_WAKEUP_BRIGHTNESS="$(get_num wakeup_brightness 80)"
    CFG_KILL_RECORDING="$(get_bool kill_recording    true)"
    CFG_HIBERNATE_THRESHOLD="$(get_num hibernate_threshold 15)"

    log_debug "Profile: mode=$CFG_MODE grace=${CFG_GRACE_PERIOD}s"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BATTERY CHECKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_battery_info() {
    local capacity=100
    local status="Unknown"
    local charging=false

    # Try multiple BAT devices
    local bat_path=""
    for bat in BAT0 BAT1 BAT2; do
        if [[ -d "/sys/class/power_supply/$bat" ]]; then
            bat_path="/sys/class/power_supply/$bat"
            break
        fi
    done

    if [[ -n "$bat_path" ]]; then
        capacity="$(cat "${bat_path}/capacity"  2>/dev/null || echo '100')"
        status="$(cat "${bat_path}/status"      2>/dev/null || echo 'Unknown')"

        [[ "$status" == "Charging" || \
           "$status" == "Full" ]] && charging=true
    elif [[ "$HAS_UPOWER" == "true" ]]; then
        local upower_out
        upower_out="$(upower -i \
            "$(upower -e | grep BAT | head -1)" 2>/dev/null || echo '')"

        capacity="$(echo "$upower_out" | \
            grep 'percentage' | \
            grep -oP '\d+' | head -1 || echo '100')"

        local upower_state
        upower_state="$(echo "$upower_out" | \
            grep 'state:' | awk '{print $2}' || echo 'unknown')"
        [[ "$upower_state" == "charging" || \
           "$upower_state" == "fully-charged" ]] && charging=true
    elif [[ "$HAS_ACPI" == "true" ]]; then
        local acpi_out
        acpi_out="$(acpi -b 2>/dev/null | head -1 || echo '')"
        capacity="$(echo "$acpi_out" | grep -oP '\d+(?=%)' | head -1 || echo '100')"
        echo "$acpi_out" | grep -qi 'charging' && charging=true
    fi

    echo "capacity=$capacity status=$status charging=$charging"
}

_check_battery() {
    [[ "$HAS_BATTERY" == "false" ]] && return 0  # No battery = AC power
    [[ "$CFG_BATTERY_CHECK" != "true" ]] && return 0

    local battery_info
    battery_info="$(_get_battery_info)"

    local capacity charging
    capacity="$(echo "$battery_info" | grep -oP '(?<=capacity=)\d+')"
    charging="$(echo "$battery_info" | grep -oP '(?<=charging=)\w+')"

    log_debug "Battery: ${capacity}% charging=${charging}"

    # On AC power — always safe to suspend
    if [[ "$charging" == "true" ]]; then
        log_debug "On AC power — suspend safe"
        return 0
    fi

    # Check critical battery
    if (( capacity < MIN_BATTERY_FOR_HIBERNATE )); then
        log_safety "Battery critically low (${capacity}%) — blocking suspend"
        _notify_battery_critical "$capacity"
        return 1
    fi

    # Check minimum for suspend
    if (( capacity < CFG_MIN_BATTERY )); then
        log_safety "Battery below ${CFG_MIN_BATTERY}% (${capacity}%) — switching to hibernate"
        CFG_MODE="$MODE_HIBERNATE"

        _notify_battery_low "$capacity"
        return 0
    fi

    # Warn at hibernate threshold
    if (( capacity < CFG_HIBERNATE_THRESHOLD )); then
        log_warn "Low battery (${capacity}%) — using suspend-then-hibernate"
        CFG_MODE="$MODE_SUSPEND_THEN_HIBERNATE"
    fi

    return 0
}

_notify_battery_low() {
    local pct="$1"
    [[ "$HAS_NOTIFY" == "false" ]] && return 0
    notify-send \
        --urgency=normal \
        --expire-time=5000 \
        --app-name="ASH Power" \
        "${ICON_BATTERY}  Low Battery" \
        "Battery at ${pct}% — switching to hibernate" 2>/dev/null || true
}

_notify_battery_critical() {
    local pct="$1"
    [[ "$HAS_NOTIFY" == "false" ]] && return 0
    notify-send \
        --urgency=critical \
        --expire-time=0 \
        --app-name="ASH Power" \
        "${ICON_BATTERY_CRIT}  Critical Battery" \
        "Battery at ${pct}% — please connect charger. Suspend blocked." \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INHIBIT CHECKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_is_inhibited() {
    [[ "$CFG_INHIBIT_CHECK" != "true" ]] && return 1

    # 1. File-based inhibit
    if [[ -f "$SUSPEND_INHIBIT_FILE" ]]; then
        local pid reason expires
        pid="$(sed -n '1p' "$SUSPEND_INHIBIT_FILE" 2>/dev/null || echo '')"
        reason="$(sed -n '2p' "$SUSPEND_INHIBIT_FILE" 2>/dev/null || echo 'unknown')"
        expires="$(sed -n '3p' "$SUSPEND_INHIBIT_FILE" 2>/dev/null || echo '0')"
        local now
        now="$(date +%s)"

        if [[ -n "$expires" ]] && (( expires > 0 && now > expires )); then
            rm -f "$SUSPEND_INHIBIT_FILE"
        elif [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$SUSPEND_INHIBIT_FILE"
        else
            log_safety "Suspend inhibited: ${reason}"
            return 0  # Inhibited
        fi
    fi

    # 2. Systemd inhibitors (sleep)
    if [[ "$HAS_SYSTEMCTL" == "true" ]]; then
        local inhibitors
        inhibitors="$(systemd-inhibit --list --mode=block 2>/dev/null | \
            grep -c 'sleep' || echo '0')"
        if (( inhibitors > 0 )); then
            log_safety "systemd sleep inhibitor active ($inhibitors)"
            return 0
        fi
    fi

    # 3. Active recordings
    if [[ "$CFG_KILL_RECORDING" != "true" ]]; then
        local rec_procs=("wf-recorder" "obs" "ffmpeg" "scrcpy")
        for proc in "${rec_procs[@]}"; do
            if pgrep -x "$proc" &>/dev/null; then
                log_warn "Recording process active: $proc"
                return 0
            fi
        done
    fi

    # 4. Docker containers with no-sleep labels
    if [[ "$HAS_DOCKER" == "true" && "$CFG_STOP_DOCKER" == "false" ]]; then
        local running_containers
        running_containers="$(docker ps -q 2>/dev/null | wc -l || echo '0')"
        if (( running_containers > 0 )); then
            log_warn "$running_containers Docker container(s) running"
            # Note: this is just a warning, not a hard block
        fi
    fi

    # 5. Active SSH sessions
    local ssh_sessions
    ssh_sessions="$(who 2>/dev/null | grep -c 'pts/' || echo '0')"
    if (( ssh_sessions > 0 )); then
        log_warn "$ssh_sessions active SSH/remote session(s)"
        # Warning only — don't block suspend for SSH
    fi

    return 1  # Not inhibited
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TRANSFER CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_active_transfers() {
    [[ "$CFG_WARN_TRANSFERS" != "true" ]] && return 0

    local device
    device="$(ip route 2>/dev/null | grep default | \
        awk '{print $5}' | head -1 || echo 'eth0')"

    [[ -z "$device" ]] && return 0

    local rx_file="/sys/class/net/${device}/statistics/rx_bytes"
    local tx_file="/sys/class/net/${device}/statistics/tx_bytes"

    [[ ! -f "$rx_file" || ! -f "$tx_file" ]] && return 0

    local rx1 tx1 rx2 tx2
    rx1="$(cat "$rx_file" 2>/dev/null || echo 0)"
    tx1="$(cat "$tx_file" 2>/dev/null || echo 0)"
    sleep 1
    rx2="$(cat "$rx_file" 2>/dev/null || echo 0)"
    tx2="$(cat "$tx_file" 2>/dev/null || echo 0)"

    local rx_rate tx_rate
    rx_rate=$(( (rx2 - rx1) / 1024 ))
    tx_rate=$(( (tx2 - tx1) / 1024 ))

    if (( rx_rate > CFG_TRANSFER_WARN_KB || \
          tx_rate > CFG_TRANSFER_WARN_KB )); then
        log_warn "Active network transfer: ↓${rx_rate}KB/s ↑${tx_rate}KB/s"

        if [[ "$HAS_NOTIFY" == "true" ]]; then
            notify-send \
                --urgency=normal \
                --expire-time=8000 \
                --app-name="ASH Power" \
                "${ICON_WARNING}  Active Transfer" \
                "Network: ↓${rx_rate}KB/s ↑${tx_rate}KB/s — suspending anyway" \
                2>/dev/null || true
        fi
    fi

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MEDIA MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_save_and_pause_media() {
    [[ "$CFG_PAUSE_MEDIA" != "true" ]] && return 0
    [[ "$HAS_PLAYERCTL" == "false" ]] && return 0

    local state_json='{"players":[]}'
    local players
    players="$(playerctl -l 2>/dev/null || echo '')"

    while IFS= read -r player; do
        [[ -z "$player" ]] && continue
        local status position
        status="$(playerctl -p "$player" status 2>/dev/null || echo 'Stopped')"
        position="$(playerctl -p "$player" position 2>/dev/null || echo '0')"

        state_json="$(echo "$state_json" | jq \
            --arg player "$player" \
            --arg status "$status" \
            --arg pos    "$position" \
            '.players += [{
                "player": $player,
                "status": $status,
                "position": $pos
            }]' 2>/dev/null)"
    done <<< "$players"

    echo "$state_json" > "$SUSPEND_MEDIA_STATE"

    # Pause all
    playerctl -a pause 2>/dev/null || true
    log_debug "Media paused and state saved"
}

_restore_media() {
    [[ "$CFG_RESUME_MEDIA" != "true" ]] && return 0
    [[ "$HAS_PLAYERCTL" == "false" ]] && return 0
    [[ ! -f "$SUSPEND_MEDIA_STATE" ]] && return 0

    log_debug "Restoring media state…"

    jq -r '.players[] | select(.status == "Playing") | .player' \
        "$SUSPEND_MEDIA_STATE" 2>/dev/null | \
    while IFS= read -r player; do
        [[ -z "$player" ]] && continue
        playerctl -p "$player" play 2>/dev/null || true
        log_debug "Resumed: $player"
    done

    rm -f "$SUSPEND_MEDIA_STATE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NETWORK STATE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_save_network_state() {
    [[ "$CFG_SAVE_NETWORK_STATE" != "true" ]] && return 0
    [[ "$HAS_NMCLI" == "false" ]] && return 0

    log_debug "Saving network state…"

    local wifi_ssid wifi_state vpn_active
    wifi_ssid="$(nmcli -t -f ACTIVE,SSID dev wifi 2>/dev/null | \
        grep '^yes' | cut -d: -f2 | head -1 || echo '')"
    wifi_state="$(nmcli radio wifi 2>/dev/null || echo 'unknown')"
    vpn_active="$(nmcli con show --active 2>/dev/null | \
        grep -c vpn || echo '0')"

    jq -n \
        --arg ssid   "$wifi_ssid" \
        --arg wifi   "$wifi_state" \
        --argjson vpn "$vpn_active" \
        --arg ts     "$(date -Iseconds)" \
        '{
            "wifi_ssid":   $ssid,
            "wifi_state":  $wifi,
            "vpn_active":  $vpn,
            "saved_at":    $ts
        }' > "$SUSPEND_NETWORK_STATE"

    log_debug "Network state saved: ssid='$wifi_ssid' wifi=$wifi_state"
}

_disconnect_vpn() {
    [[ "$CFG_DISCONNECT_VPN" != "true" ]] && return 0
    [[ "$HAS_NMCLI" == "false" ]] && return 0

    log_debug "Disconnecting VPN connections…"

    nmcli con show --active 2>/dev/null | grep vpn | awk '{print $1}' | \
    while IFS= read -r vpn_name; do
        [[ -z "$vpn_name" ]] && continue
        nmcli con down "$vpn_name" 2>/dev/null || true
        log_debug "VPN disconnected: $vpn_name"
    done
}

_disconnect_bluetooth_devices() {
    [[ "$CFG_DISCONNECT_BLUETOOTH" != "true" ]] && return 0
    [[ "$HAS_BLUETOOTHCTL" == "false" ]] && return 0

    log_debug "Disconnecting Bluetooth devices…"

    # Get connected devices
    bluetoothctl devices Connected 2>/dev/null | \
    while IFS=' ' read -r _ mac _; do
        [[ -z "$mac" ]] && continue
        bluetoothctl disconnect "$mac" &>/dev/null || true
        log_debug "BT disconnected: $mac"
    done
}

_restore_network() {
    [[ "$CFG_RESTORE_NETWORK" != "true" ]] && return 0
    [[ "$HAS_NMCLI" == "false" ]] && return 0
    [[ ! -f "$SUSPEND_NETWORK_STATE" ]] && return 0

    log_debug "Restoring network state…"

    local wifi_state
    wifi_state="$(jq -r '.wifi_state // "enabled"' \
        "$SUSPEND_NETWORK_STATE" 2>/dev/null || echo 'enabled')"

    if [[ "$wifi_state" == "enabled" ]]; then
        nmcli radio wifi on 2>/dev/null || true
    fi

    rm -f "$SUSPEND_NETWORK_STATE"
    log_debug "Network state restored"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DOCKER / CONTAINER MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_stop_docker_containers() {
    [[ "$CFG_STOP_DOCKER" != "true" ]] && return 0

    if [[ "$HAS_DOCKER" == "true" ]]; then
        local containers
        containers="$(docker ps -q 2>/dev/null)"
        if [[ -n "$containers" ]]; then
            log_debug "Stopping Docker containers…"
            echo "$containers" | xargs docker stop --time=10 &>/dev/null || true
            log_debug "Docker containers stopped"
        fi
    fi

    if [[ "$HAS_PODMAN" == "true" ]]; then
        local pods
        pods="$(podman ps -q 2>/dev/null)"
        if [[ -n "$pods" ]]; then
            echo "$pods" | xargs podman stop --time=10 &>/dev/null || true
            log_debug "Podman containers stopped"
        fi
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# RECORDING CHECK & KILL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_stop_recordings() {
    [[ "$CFG_KILL_RECORDING" != "true" ]] && return 0

    local recording_procs=("wf-recorder" "scrcpy")

    for proc in "${recording_procs[@]}"; do
        if pgrep -x "$proc" &>/dev/null; then
            log_debug "Gracefully stopping: $proc"
            pkill -SIGINT -x "$proc" 2>/dev/null || true
            sleep 1
            pkill -x "$proc" 2>/dev/null || true
        fi
    done

    # Send OBS stop-recording signal if running
    if pgrep -x obs &>/dev/null && command -v obs-cmd &>/dev/null; then
        obs-cmd recording stop 2>/dev/null || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SYNC & FLUSH
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sync_filesystems() {
    [[ "$CFG_SYNC_BEFORE" != "true" ]] && return 0

    log_debug "Syncing filesystems…"

    # sync with timeout
    timeout "$SYNC_TIMEOUT" sync 2>/dev/null || true

    # Drop caches (optional — uncomment if needed)
    # echo 3 > /proc/sys/vm/drop_caches 2>/dev/null || true

    log_debug "Filesystems synced"
}

_check_unsaved_files() {
    # Check for common editors with unsaved changes
    local editors_with_unsaved=()

    # Check nvim swap files (indicate unsaved buffers)
    local nvim_swaps
    nvim_swaps="$(find "${XDG_STATE_HOME:-$HOME/.local/state}/nvim" \
        -name '*.swp' 2>/dev/null | wc -l)"
    (( nvim_swaps > 0 )) && \
        editors_with_unsaved+=("nvim ($nvim_swaps unsaved buffers)")

    # Check vim swap files
    local vim_swaps
    vim_swaps="$(find "$HOME" -name '.*.swp' -maxdepth 5 2>/dev/null | wc -l)"
    (( vim_swaps > 0 )) && \
        editors_with_unsaved+=("vim ($vim_swaps)")

    if (( ${#editors_with_unsaved[@]} > 0 )); then
        log_warn "Possible unsaved files: ${editors_with_unsaved[*]}"
        # Non-blocking warning
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SESSION SAVE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_save_session_state() {
    [[ "$CFG_SAVE_SESSION" != "true" ]] && return 0
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    log_debug "Saving session state…"

    local session_json
    session_json="$(jq -n \
        --argjson clients "$(hyprctl clients -j 2>/dev/null || echo '[]')" \
        --argjson monitors "$(hyprctl monitors -j 2>/dev/null || echo '[]')" \
        --argjson workspaces "$(hyprctl workspaces -j 2>/dev/null || echo '[]')" \
        --arg ts "$(date -Iseconds)" \
        '{
            "saved_at":   $ts,
            "clients":    $clients,
            "monitors":   $monitors,
            "workspaces": $workspaces
        }')"

    echo "$session_json" > "${CACHE_DIR}/suspend-session.json"
    log_debug "Session state saved"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GRACE PERIOD
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_grace_period() {
    local seconds="${1:-$CFG_GRACE_PERIOD}"
    (( seconds <= 0 )) && return 0

    log_info "Suspend grace period: ${seconds}s"

    if [[ "$HAS_NOTIFY" == "true" ]]; then
        notify-send \
            --urgency=normal \
            --expire-time=$(( seconds * 1000 )) \
            --app-name="ASH Power" \
            "${ICON_SLEEP}  Suspending in ${seconds}s" \
            "Press a key or move mouse to cancel" 2>/dev/null || true
    fi

    local remaining=$seconds
    while (( remaining > 0 )); do
        sleep 1
        (( remaining-- )) || true

        # Activity check via hyprctl
        if [[ "$HAS_HYPRCTL" == "true" ]]; then
            local idle_ms
            idle_ms="$(hyprctl idle 2>/dev/null | \
                grep -oP '\d+' | head -1 || echo '999999')"
            if (( idle_ms < 1000 )); then
                log_info "Grace period cancelled — user activity"
                return 1
            fi
        fi
    done

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VISUAL PRE-SUSPEND
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_pre_suspend_visual() {
    [[ "$CFG_DIM_BEFORE" != "true" ]] && return 0

    local dim_script="${SCRIPT_DIR}/dim-screen.sh"
    if [[ -x "$dim_script" ]]; then
        "$dim_script" \
            --level 3 \
            --duration 1200 \
            --steps 30 \
            --easing "ease-in" \
            --force \
            &>/dev/null || true
    elif [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        brightnessctl set "3%" -q 2>/dev/null || true
    fi

    log_debug "Pre-suspend dim applied"
}

_save_brightness_for_resume() {
    if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        local current
        current="$(brightnessctl -m 2>/dev/null | \
            awk -F, '{gsub(/%/,"",$4); print int($4)}')"
        echo "${current:-80}" > "${RUNTIME_DIR}/suspend-brightness.tmp"
        log_debug "Saved brightness: ${current}%"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAYBAR / STATUS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_waybar() {
    local signal="${CFG_WAYBAR_SIGNAL:-10}"
    pkill -SIGRTMIN+${signal} waybar 2>/dev/null || true
    log_debug "Waybar signaled SIGRTMIN+${signal}"
}

_update_status() {
    local state="$1"

    jq -n \
        --arg state "$state" \
        --arg ts    "$(date -Iseconds)" \
        --arg mode  "$CFG_MODE" \
        '{"state":$state,"mode":$mode,"timestamp":$ts}' \
        > "${RUNTIME_DIR}/suspend-status.json" 2>/dev/null || true

    _signal_waybar
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SOUND & NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_play_sound() {
    local file="$1"
    local enabled="${2:-true}"
    [[ "$enabled" != "true" ]] && return 0
    [[ ! -f "$file" ]] && return 0

    if   command -v pw-play &>/dev/null; then
        pw-play   --volume=0.5 "$file" &>/dev/null &
    elif command -v paplay  &>/dev/null; then
        paplay    --volume=32768 "$file" &>/dev/null &
    elif command -v ogg123  &>/dev/null; then
        ogg123    -q "$file" &>/dev/null &
    fi
    disown 2>/dev/null || true
    # Brief wait for sound to play before suspend
    sleep 0.8
}

_notify_suspend() {
    [[ "$HAS_NOTIFY" == "false" ]] && return 0
    [[ "$CFG_NOTIFY_SUSPEND" != "true" ]] && return 0

    local mode_label
    case "$CFG_MODE" in
        suspend)                   mode_label="Suspending" ;;
        hibernate)                 mode_label="Hibernating" ;;
        hybrid-sleep)              mode_label="Hybrid Sleep" ;;
        suspend-then-hibernate)    mode_label="Suspend → Hibernate" ;;
        *)                         mode_label="Sleeping" ;;
    esac

    notify-send \
        --urgency=low \
        --expire-time=2000 \
        --app-name="ASH Power" \
        "${ICON_SLEEP}  ${mode_label}…" \
        "See you later 🌙" 2>/dev/null || true
}

_notify_resume() {
    [[ "$HAS_NOTIFY" == "false" ]] && return 0
    [[ "$CFG_NOTIFY_RESUME" != "true" ]] && return 0

    local sleep_duration="${1:-0}"
    local dur_str=""

    if (( sleep_duration > 0 )); then
        local h m
        h=$(( sleep_duration / 3600 ))
        m=$(( (sleep_duration % 3600) / 60 ))
        if (( h > 0 )); then
            dur_str="${h}h ${m}m"
        else
            dur_str="${m}m"
        fi
    fi

    notify-send \
        --urgency=low \
        --expire-time=4000 \
        --app-name="ASH Power" \
        "${ICON_WAKE}  Welcome back!" \
        "${dur_str:+Slept for ${dur_str}  •  }$(date '+%H:%M')" \
        2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANALYTICS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_record_suspend_event() {
    local event="$1"       # suspend | resume | blocked
    local metadata="${2:-{}}"

    [[ "$CFG_ANALYTICS" != "true" ]] && return 0
    [[ "$HAS_JQ" == "false" ]] && return 0

    [[ ! -f "$SUSPEND_HISTORY_FILE" ]] && \
        echo '{"events":[],"total_suspends":0,"total_sleep_secs":0}' \
        > "$SUSPEND_HISTORY_FILE"

    jq \
        --arg  event "$event" \
        --arg  ts    "$(date -Iseconds)" \
        --arg  mode  "$CFG_MODE" \
        --argjson meta "$metadata" \
        '.events += [{
            "event":     $event,
            "timestamp": $ts,
            "mode":      $mode,
            "metadata":  $meta
        }] |
        .events = .events[-500:] |
        if $event == "suspend" then .total_suspends += 1 else . end' \
        "$SUSPEND_HISTORY_FILE" \
        > "${SUSPEND_HISTORY_FILE}.tmp" 2>/dev/null && \
    mv "${SUSPEND_HISTORY_FILE}.tmp" "$SUSPEND_HISTORY_FILE"

    log_debug "Suspend analytics: $event"
}

_update_sleep_stats() {
    local sleep_duration="$1"

    [[ "$CFG_ANALYTICS" != "true" ]] && return 0
    [[ "$HAS_JQ" == "false" ]] && return 0

    local date_key
    date_key="$(date '+%Y-%m-%d')"

    [[ ! -f "$SUSPEND_STATS_FILE" ]] && \
        echo '{"daily":{},"total_sleep_secs":0}' > "$SUSPEND_STATS_FILE"

    jq \
        --arg date "$date_key" \
        --argjson dur "$sleep_duration" \
        '.daily[$date] = (.daily[$date] // {"suspends":0,"sleep_secs":0}) |
         .daily[$date].suspends   += 1 |
         .daily[$date].sleep_secs += $dur |
         .total_sleep_secs        += $dur' \
        "$SUSPEND_STATS_FILE" \
        > "${SUSPEND_STATS_FILE}.tmp" 2>/dev/null && \
    mv "${SUSPEND_STATS_FILE}.tmp" "$SUSPEND_STATS_FILE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ON-RESUME HANDLER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_on_resume() {
    log_info "System resumed — running post-resume sequence…"

    # Calculate sleep duration
    local sleep_duration=0
    if [[ -f "$SUSPEND_TIMESTAMP_FILE" ]]; then
        local suspend_ts now_ts
        suspend_ts="$(cat "$SUSPEND_TIMESTAMP_FILE" 2>/dev/null || echo 0)"
        now_ts="$(date +%s)"
        sleep_duration=$(( now_ts - suspend_ts ))
        rm -f "$SUSPEND_TIMESTAMP_FILE"
    fi

    log_info "Sleep duration: ${sleep_duration}s"

    # 1. Restore brightness
    local undim_script="${SCRIPT_DIR}/undim-screen.sh"
    if [[ -x "$undim_script" ]]; then
        "$undim_script" --force &>/dev/null & true
    elif [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        local saved_brightness
        saved_brightness="$(cat "${RUNTIME_DIR}/suspend-brightness.tmp" \
            2>/dev/null || echo "$CFG_WAKEUP_BRIGHTNESS")"
        brightnessctl set "${saved_brightness}%" -q 2>/dev/null || true
        rm -f "${RUNTIME_DIR}/suspend-brightness.tmp"
    fi

    # 2. DPMS on
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        hyprctl dispatch dpms on 2>/dev/null || true
    fi

    # 3. Restore compositor
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        hyprctl keyword decoration:active_opacity   "1.0" &>/dev/null || true
        hyprctl keyword decoration:inactive_opacity "1.0" &>/dev/null || true
    fi

    # 4. Restore network
    _restore_network

    # 5. Restore media
    _restore_media

    # 6. Update state
    echo "resumed" > "$SUSPEND_STATE_FILE"
    _update_status "resumed"

    # 7. Analytics
    _record_suspend_event "resume" \
        "{\"sleep_duration_secs\": $sleep_duration}"
    _update_sleep_stats "$sleep_duration"

    # 8. Sound
    _play_sound "$SOUND_RESUME" "$CFG_SOUND_RESUME"

    # 9. Notification
    _notify_resume "$sleep_duration"

    # 10. Signal Waybar
    _signal_waybar

    # 11. Run on-resume hook
    local hook="${CONFIG_DIR}/hooks/on-resume.sh"
    [[ -f "$hook" && -x "$hook" ]] && \
        SLEEP_DURATION="$sleep_duration" "$hook" & true

    log_success "Resume complete (slept ${sleep_duration}s)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE SUSPEND OPERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_execute_suspend() {
    local mode="${1:-$CFG_MODE}"

    case "$SUSPEND_BACKEND" in
        systemctl)
            log_info "Executing: systemctl $mode"
            systemctl "$mode" 2>&1 | head -5 || true
            ;;
        loginctl)
            case "$mode" in
                suspend)   loginctl suspend   2>/dev/null ;;
                hibernate) loginctl hibernate 2>/dev/null ;;
                *)         loginctl suspend   2>/dev/null ;;
            esac
            ;;
        sysfs)
            log_info "Executing suspend via sysfs"
            local sysfs_mode
            case "$mode" in
                hibernate) sysfs_mode="disk"   ;;
                *)         sysfs_mode="mem"    ;;
            esac
            sync
            echo "$sysfs_mode" > /sys/power/state 2>/dev/null || {
                log_error "sysfs suspend failed"
                return 1
            }
            ;;
        none)
            log_error "No suspend backend available"
            return 1
            ;;
    esac
}

_do_suspend() {
    local force="${1:-false}"
    local mode_override="${2:-}"
    local reason="${3:-idle}"

    # Apply mode override
    [[ -n "$mode_override" ]] && CFG_MODE="$mode_override"

    log_info "Initiating suspend: mode=$CFG_MODE reason=$reason force=$force"
    echo "$reason" > "$SUSPEND_REASON_FILE"

    # ── Phase 1: Safety checks ────────────────────────────────────────────

    # Battery check (may change mode to hibernate)
    if ! _check_battery; then
        log_safety "Battery safety check failed — abort suspend"
        _record_suspend_event "blocked" \
            '{"reason":"battery_critical"}'
        return 1
    fi

    # Inhibit check
    if [[ "$force" == "false" ]] && _is_inhibited; then
        log_info "Suspend inhibited — skipping"
        _record_suspend_event "blocked" '{"reason":"inhibited"}'
        return 0
    fi

    # Check unsaved files (non-blocking)
    _check_unsaved_files

    # Check active transfers (non-blocking warning)
    _check_active_transfers

    # ── Phase 2: Grace period ────────────────────────────────────────────
    if ! _grace_period "$CFG_GRACE_PERIOD"; then
        log_info "Suspend cancelled during grace period"
        return 0
    fi

    # ── Phase 3: Pre-suspend sequence ────────────────────────────────────
    _update_status "suspending"
    echo "suspending" > "$SUSPEND_STATE_FILE"

    # Lock session first (if configured)
    if [[ "$CFG_LOCK_BEFORE_SUSPEND" == "true" ]]; then
        local lock_script="${SCRIPT_DIR}/lock-session.sh"
        if [[ -x "$lock_script" ]]; then
            log_info "Locking session before suspend…"
            # Run lock in background — don't wait for unlock
            "$lock_script" \
                --no-dim \
                --no-blur \
                --grace 0 \
                &>/dev/null &
            sleep 1  # Give lock time to start
        fi
    fi

    # Save state
    _save_session_state
    _save_brightness_for_resume
    _save_network_state
    _save_and_pause_media

    # Stop recordings
    _stop_recordings

    # Stop containers
    _stop_docker_containers

    # Disconnect peripherals
    _disconnect_vpn
    _disconnect_bluetooth_devices

    # Sync filesystems
    _sync_filesystems

    # Visual effects (dim screen)
    _pre_suspend_visual

    # Sound (play before suspend)
    _play_sound "$SOUND_SUSPEND" "$CFG_SOUND_SUSPEND"

    # Notification
    _notify_suspend

    # Analytics
    _record_suspend_event "suspend" \
        "$(jq -n \
            --arg mode   "$CFG_MODE" \
            --arg reason "$reason" \
            '{"mode":$mode,"reason":$reason}' 2>/dev/null || echo '{}')"

    # Pre-suspend hook
    local pre_hook="${CONFIG_DIR}/hooks/on-suspend.sh"
    [[ -f "$pre_hook" && -x "$pre_hook" ]] && \
        SUSPEND_MODE="$CFG_MODE" SUSPEND_REASON="$reason" \
        "$pre_hook" 2>/dev/null || true

    # Save timestamp
    date +%s > "$SUSPEND_TIMESTAMP_FILE"

    # Final waybar update
    _update_status "suspended"
    echo "suspended" > "$SUSPEND_STATE_FILE"

    # ── Phase 4: SUSPEND ─────────────────────────────────────────────────
    log_safety "Executing $CFG_MODE…"

    _execute_suspend "$CFG_MODE"

    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    # EXECUTION CONTINUES HERE AFTER WAKEUP
    # ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

    log_info "System resumed from $CFG_MODE"

    # ── Phase 5: Post-resume sequence ────────────────────────────────────
    _on_resume
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATUS & HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_status() {
    local format="${1:-human}"

    local state
    state="$(cat "$SUSPEND_STATE_FILE" 2>/dev/null || echo 'unknown')"

    local battery_info capacity="" charging="false"
    if [[ "$HAS_BATTERY" == "true" ]]; then
        battery_info="$(_get_battery_info)"
        capacity="$(echo "$battery_info" | grep -oP '(?<=capacity=)\d+')"
        charging="$(echo "$battery_info" | grep -oP '(?<=charging=)\w+')"
    fi

    case "$format" in
        json)
            jq -n \
                --arg state    "$state" \
                --arg mode     "$CFG_MODE" \
                --arg backend  "$SUSPEND_BACKEND" \
                --arg capacity "$capacity" \
                --arg charging "$charging" \
                --arg ts       "$(date -Iseconds)" \
                '{
                    "state":    $state,
                    "mode":     $mode,
                    "backend":  $backend,
                    "battery":  {
                        "capacity": ($capacity | if . == "" then null else . | tonumber end),
                        "charging": ($charging == "true")
                    },
                    "timestamp":$ts
                }'
            ;;
        waybar)
            local text tooltip class
            if [[ "$state" == "suspended" || "$state" == "suspending" ]]; then
                text="${ICON_SLEEP}"
                tooltip="System suspending"
                class="suspended"
            else
                text="${ICON_WAKE}"
                local batt_str=""
                [[ -n "$capacity" ]] && batt_str="  •  ${capacity}%"
                tooltip="System active${batt_str}"
                class="active"
            fi
            jq -n \
                --arg text    "$text" \
                --arg tooltip "$tooltip" \
                --arg class   "$class" \
                '{"text":$text,"tooltip":$tooltip,"class":$class}'
            ;;
        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_ASH}  ASH Suspend Status${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            echo -e "  State   : ${CLR_WHITE}${state}${CLR_RESET}"
            echo -e "  Mode    : ${CLR_CYAN}${CFG_MODE}${CLR_RESET}"
            echo -e "  Backend : ${CLR_WHITE}${SUSPEND_BACKEND}${CLR_RESET}"

            if [[ -n "$capacity" ]]; then
                local batt_color="$CLR_GREEN"
                (( capacity < 30 )) && batt_color="$CLR_YELLOW"
                (( capacity < 15 )) && batt_color="$CLR_RED"
                echo -e "  Battery : ${batt_color}${capacity}%${CLR_RESET} \
(${charging})"
            fi

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

_show_history() {
    local limit="${1:-10}"
    [[ ! -f "$SUSPEND_HISTORY_FILE" ]] && { echo "[]"; return; }

    jq \
        --argjson limit "$limit" \
        '.events | .[-($limit):] | reverse' \
        "$SUSPEND_HISTORY_FILE" 2>/dev/null || echo "[]"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH Suspend v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [OPTIONS]

${CLR_BOLD}SUSPEND MODES${CLR_RESET}
  ${CLR_GREEN}(no args)${CLR_RESET}              Suspend (RAM)
  ${CLR_GREEN}--hibernate${CLR_RESET}            Hibernate to disk
  ${CLR_GREEN}--hybrid${CLR_RESET}               Hybrid sleep (RAM + disk)
  ${CLR_GREEN}--smart${CLR_RESET}                Auto-select based on battery

${CLR_BOLD}OPTIONS${CLR_RESET}
  ${CLR_YELLOW}--force, -f${CLR_RESET}            Override inhibit checks
  ${CLR_YELLOW}--no-lock${CLR_RESET}              Skip pre-suspend lock
  ${CLR_YELLOW}--no-sync${CLR_RESET}              Skip filesystem sync
  ${CLR_YELLOW}--no-media${CLR_RESET}             Skip media pause
  ${CLR_YELLOW}--grace N${CLR_RESET}              Grace period (seconds)
  ${CLR_YELLOW}--reason TEXT${CLR_RESET}          Reason label (analytics)

${CLR_BOLD}STATUS${CLR_RESET}
  ${CLR_CYAN}--status${CLR_RESET}               Human status
  ${CLR_CYAN}--status=json${CLR_RESET}          JSON status
  ${CLR_CYAN}--status=waybar${CLR_RESET}        Waybar module JSON
  ${CLR_CYAN}--history${CLR_RESET}              Suspend history
  ${CLR_CYAN}--history N${CLR_RESET}            Last N events
  ${CLR_CYAN}--battery${CLR_RESET}              Battery info

${CLR_BOLD}MISC${CLR_RESET}
  ${CLR_WHITE}--version${CLR_RESET}              Show version
  ${CLR_WHITE}--help${CLR_RESET}                 Show help

${CLR_BOLD}EXAMPLES${CLR_RESET}
  $(basename "$0")                       # Standard suspend
  $(basename "$0") --hibernate           # Hibernate
  $(basename "$0") --smart               # Auto-mode
  $(basename "$0") --grace 10 --force    # 10s grace, ignore inhibit
  $(basename "$0") --status=json         # JSON status

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    _ensure_dirs
    _detect_capabilities
    _load_profile
    _acquire_lock || { log_error "Suspend already in progress"; exit 1; }

    local force=false
    local mode_override=""
    local grace_override=""
    local reason="user"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)         force=true ;;
            --hibernate)        mode_override="$MODE_HIBERNATE" ;;
            --hybrid)           mode_override="$MODE_HYBRID" ;;
            --smart)
                # Auto-select: check battery
                if [[ "$HAS_BATTERY" == "true" ]]; then
                    local bat_info cap
                    bat_info="$(_get_battery_info)"
                    cap="$(echo "$bat_info" | \
                        grep -oP '(?<=capacity=)\d+')"
                    if (( cap < CFG_HIBERNATE_THRESHOLD )); then
                        mode_override="$MODE_HIBERNATE"
                    else
                        mode_override="$MODE_SUSPEND"
                    fi
                else
                    mode_override="$MODE_SUSPEND"
                fi
                ;;
            --no-lock)          CFG_LOCK_BEFORE_SUSPEND=false ;;
            --no-sync)          CFG_SYNC_BEFORE=false ;;
            --no-media)         CFG_PAUSE_MEDIA=false ;;
            --no-dim)           CFG_DIM_BEFORE=false ;;
            --grace)            shift; grace_override="${1:-0}" ;;
            --grace=*)          grace_override="${1#--grace=}" ;;
            --reason)           shift; reason="${1:-user}" ;;
            --reason=*)         reason="${1#--reason=}" ;;
            --status)           _show_status human;  exit 0 ;;
            --status=json)      _show_status json;   exit 0 ;;
            --status=waybar)    _show_status waybar; exit 0 ;;
            --status=*)         _show_status "${1#--status=}"; exit 0 ;;
            --history)
                shift
                _show_history "${1:-10}"
                exit 0
                ;;
            --history=*)
                _show_history "${1#--history=}"
                exit 0
                ;;
            --battery)
                _get_battery_info | tr ' ' '\n'
                exit 0
                ;;
            --version)
                echo "$SCRIPT_NAME v$SCRIPT_VERSION"
                exit 0
                ;;
            --help|-h)
                _show_help
                exit 0
                ;;
            *)
                log_warn "Unknown: $1"
                ;;
        esac
        shift 2>/dev/null || break
    done

    # Apply grace override
    [[ -n "$grace_override" ]] && CFG_GRACE_PERIOD="$grace_override"

    _do_suspend "$force" "$mode_override" "$reason"
    exit 0
}

main "$@"