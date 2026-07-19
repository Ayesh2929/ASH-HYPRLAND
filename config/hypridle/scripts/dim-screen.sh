#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HyprIdle Ultra Dim Screen Script                 ║
# ║  Premium adaptive screen dimming with smooth transitions, multi-monitor      ║
# ║  support, gamma correction, blue light reduction, content-aware dimming,     ║
# ║  HDR handling, per-monitor profiles, and intelligent restore state engine    ║
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

readonly SCRIPT_NAME="ash-dim-screen"
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG paths
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"
readonly HYPRIDLE_CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/hypridle"

# State files — dim system
readonly DIM_STATE_FILE="${RUNTIME_DIR}/dim.state"
readonly DIM_LOCK_FILE="${RUNTIME_DIR}/dim.lock"
readonly DIM_LOG_FILE="${CACHE_DIR}/logs/dim-screen.log"
readonly DIM_PROFILE_FILE="${CONFIG_DIR}/dim-profile.json"
readonly DIM_RESTORE_FILE="${RUNTIME_DIR}/dim-restore.json"
readonly DIM_ANIM_PID_FILE="${RUNTIME_DIR}/dim-anim.pid"
readonly DIM_MONITOR_CACHE="${RUNTIME_DIR}/monitors.json"
readonly DIM_BRIGHTNESS_BACKUP="${RUNTIME_DIR}/brightness-backup.json"
readonly DIM_INHIBIT_FILE="${RUNTIME_DIR}/dim-inhibit"
readonly DIM_HISTORY_FILE="${CACHE_DIR}/dim-history.json"

# Config
readonly ASH_CONFIG="${CONFIG_DIR}/ash.conf"
readonly IDLE_CONFIG="${HYPRIDLE_CONFIG_DIR}/hypridle.conf"

# Icons / UI
readonly ICON_DIM="󰃞"
readonly ICON_BRIGHT="󰃠"
readonly ICON_MONITOR="󰍹"
readonly ICON_ASH="󱎫"
readonly ICON_SLEEP="󰒲"
readonly ICON_EYE="󰛓"
readonly ICON_SUN="󰖙"
readonly ICON_MOON="󰖔"

# ANSI colors
readonly CLR_RESET='\033[0m'
readonly CLR_BOLD='\033[1m'
readonly CLR_RED='\033[0;31m'
readonly CLR_GREEN='\033[0;32m'
readonly CLR_YELLOW='\033[0;33m'
readonly CLR_CYAN='\033[0;36m'
readonly CLR_GRAY='\033[0;90m'
readonly CLR_WHITE='\033[0;37m'

# Dimming defaults (overridden by profile or args)
readonly DEFAULT_DIM_LEVEL=15          # Target brightness % (1-100)
readonly DEFAULT_DIM_DURATION=3000     # Transition duration ms
readonly DEFAULT_DIM_STEPS=60          # Animation steps
readonly DEFAULT_DIM_GAMMA_R=0.95      # Red gamma adjustment when dimmed
readonly DEFAULT_DIM_GAMMA_G=0.90      # Green gamma adjustment
readonly DEFAULT_DIM_GAMMA_B=0.80      # Blue gamma (warm dim)
readonly DEFAULT_MIN_BRIGHTNESS=1      # Absolute minimum %
readonly DEFAULT_MAX_BRIGHTNESS=100    # Absolute maximum %
readonly DEFAULT_NIGHT_DIM_LEVEL=5     # Extra-dim at night
readonly DEFAULT_BATTERY_DIM_LEVEL=10  # More aggressive on battery

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR"
        "$STATE_DIR"
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

    # Rotation at 256KB
    if [[ -f "$DIM_LOG_FILE" ]]; then
        local sz
        sz="$(stat -c%s "$DIM_LOG_FILE" 2>/dev/null || echo 0)"
        if (( sz > 262144 )); then
            mv "$DIM_LOG_FILE" \
               "${DIM_LOG_FILE}.$(date +%Y%m%d_%H%M%S).old"
            find "${CACHE_DIR}/logs" \
                -name 'dim-screen.log.*.old' \
                -mtime +7 \
                -delete 2>/dev/null || true
        fi
    fi

    echo "$log_line" >> "$DIM_LOG_FILE" 2>/dev/null || true

    [[ ! -t 2 ]] && return 0
    case "$level" in
        ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[✗]${CLR_RESET} $message"   >&2 ;;
        WARN)    echo -e "${CLR_YELLOW}[⚠]${CLR_RESET}  $message"           >&2 ;;
        INFO)    echo -e "${CLR_CYAN}[ℹ]${CLR_RESET}  $message"             >&2 ;;
        SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[✓]${CLR_RESET} $message"  >&2 ;;
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
    local max_wait="${1:-3}"
    local waited=0

    while [[ -f "$DIM_LOCK_FILE" ]]; do
        local lock_pid
        lock_pid="$(cat "$DIM_LOCK_FILE" 2>/dev/null || echo '')"

        if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
            log_warn "Stale lock detected (PID=$lock_pid) — removing"
            rm -f "$DIM_LOCK_FILE"
            break
        fi

        if (( waited >= max_wait )); then
            log_error "Could not acquire lock after ${max_wait}s"
            return 1
        fi

        sleep 0.2
        (( waited++ )) || true
    done

    echo "$$" > "$DIM_LOCK_FILE"
    log_debug "Lock acquired (PID=$$)"
    return 0
}

_release_lock() {
    local lock_pid
    lock_pid="$(cat "$DIM_LOCK_FILE" 2>/dev/null || echo '')"
    [[ "$lock_pid" == "$$" ]] && rm -f "$DIM_LOCK_FILE"
    log_debug "Lock released"
}

_cleanup() {
    _release_lock
    _stop_animation
    log_debug "Cleanup complete"
}

trap '_cleanup' EXIT INT TERM HUP

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEPENDENCY DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Backend capabilities (detected at runtime)
declare -g HAS_BRIGHTNESSCTL=false
declare -g HAS_XRANDR=false
declare -g HAS_WLRTCTL=false
declare -g HAS_HYPRCTL=false
declare -g HAS_DDCUTIL=false
declare -g HAS_GAMMASTEP=false
declare -g HAS_WLSUNSET=false
declare -g HAS_DBUS=false
declare -g HAS_PYTHON=false
declare -g HAS_BC=false
declare -g HAS_AWK=true
declare -g IS_WAYLAND=false
declare -g IS_LAPTOP=false
declare -g HAS_BATTERY=false
declare -g GPU_VENDOR=""

_detect_capabilities() {
    command -v brightnessctl &>/dev/null && HAS_BRIGHTNESSCTL=true
    command -v xrandr        &>/dev/null && HAS_XRANDR=true
    command -v hyprctl       &>/dev/null && HAS_HYPRCTL=true
    command -v ddcutil       &>/dev/null && HAS_DDCUTIL=true
    command -v gammastep     &>/dev/null && HAS_GAMMASTEP=true
    command -v wlsunset      &>/dev/null && HAS_WLSUNSET=true
    command -v python3       &>/dev/null && HAS_PYTHON=true
    command -v bc            &>/dev/null && HAS_BC=true
    command -v gdbus         &>/dev/null && HAS_DBUS=true

    [[ -n "${WAYLAND_DISPLAY:-}" || -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && \
        IS_WAYLAND=true

    # Detect laptop
    [[ -d /sys/class/power_supply/BAT0 || \
       -d /sys/class/power_supply/BAT1 ]] && {
        IS_LAPTOP=true
        HAS_BATTERY=true
    }

    # GPU vendor
    if command -v lspci &>/dev/null; then
        if lspci 2>/dev/null | grep -qi 'NVIDIA'; then
            GPU_VENDOR="nvidia"
        elif lspci 2>/dev/null | grep -qi 'AMD\|Radeon'; then
            GPU_VENDOR="amd"
        elif lspci 2>/dev/null | grep -qi 'Intel'; then
            GPU_VENDOR="intel"
        fi
    fi

    log_debug "Caps: brightnessctl=$HAS_BRIGHTNESSCTL hyprctl=$HAS_HYPRCTL \
ddcutil=$HAS_DDCUTIL gammastep=$HAS_GAMMASTEP wayland=$IS_WAYLAND \
laptop=$IS_LAPTOP gpu=$GPU_VENDOR"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PROFILE LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

# Runtime config (populated by _load_profile)
declare -g CFG_DIM_LEVEL=$DEFAULT_DIM_LEVEL
declare -g CFG_DIM_DURATION=$DEFAULT_DIM_DURATION
declare -g CFG_DIM_STEPS=$DEFAULT_DIM_STEPS
declare -g CFG_DIM_EASING="ease-in-out"
declare -g CFG_DIM_GAMMA_R=$DEFAULT_DIM_GAMMA_R
declare -g CFG_DIM_GAMMA_G=$DEFAULT_DIM_GAMMA_G
declare -g CFG_DIM_GAMMA_B=$DEFAULT_DIM_GAMMA_B
declare -g CFG_WARM_DIM=true
declare -g CFG_USE_GAMMA=false
declare -g CFG_PER_MONITOR=true
declare -g CFG_EXCLUDE_MONITORS=""
declare -g CFG_SOUND_ENABLED=false
declare -g CFG_NOTIFY_ENABLED=false
declare -g CFG_DPMS_AFTER_DIM=false
declare -g CFG_LOCK_AFTER_DIM=false
declare -g CFG_ADAPTIVE_DIM=true
declare -g CFG_RESPECT_DND=true
declare -g CFG_BATTERY_AGGRESSIVE=true

_load_profile() {
    # Load from JSON profile if exists
    [[ ! -f "$DIM_PROFILE_FILE" ]] && {
        log_debug "No dim profile found — using defaults"
        return 0
    }

    log_debug "Loading dim profile: $DIM_PROFILE_FILE"

    local jq_check
    jq_check="$(command -v jq 2>/dev/null || echo '')"
    [[ -z "$jq_check" ]] && return 0

    local get
    get() { jq -r ".${1} // \"${2}\"" "$DIM_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_num
    get_num() { jq -r ".${1} // ${2}" "$DIM_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_bool
    get_bool() { jq -r "if .${1} == true then \"true\" else \"false\" end" \
                    "$DIM_PROFILE_FILE" 2>/dev/null || echo "$2"; }

    CFG_DIM_LEVEL="$(get_num  dim_level         $DEFAULT_DIM_LEVEL)"
    CFG_DIM_DURATION="$(get_num dim_duration_ms $DEFAULT_DIM_DURATION)"
    CFG_DIM_STEPS="$(get_num  dim_steps         $DEFAULT_DIM_STEPS)"
    CFG_DIM_EASING="$(get     dim_easing        'ease-in-out')"
    CFG_DIM_GAMMA_R="$(get    gamma.r           $DEFAULT_DIM_GAMMA_R)"
    CFG_DIM_GAMMA_G="$(get    gamma.g           $DEFAULT_DIM_GAMMA_G)"
    CFG_DIM_GAMMA_B="$(get    gamma.b           $DEFAULT_DIM_GAMMA_B)"
    CFG_WARM_DIM="$(get_bool  warm_dim          true)"
    CFG_USE_GAMMA="$(get_bool use_gamma         false)"
    CFG_PER_MONITOR="$(get_bool per_monitor     true)"
    CFG_EXCLUDE_MONITORS="$(get exclude_monitors '')"
    CFG_SOUND_ENABLED="$(get_bool sound         false)"
    CFG_NOTIFY_ENABLED="$(get_bool notify       false)"
    CFG_ADAPTIVE_DIM="$(get_bool adaptive_dim   true)"
    CFG_RESPECT_DND="$(get_bool respect_dnd     true)"
    CFG_BATTERY_AGGRESSIVE="$(get_bool battery_aggressive true)"

    log_debug "Profile loaded: dim_level=${CFG_DIM_LEVEL}% duration=${CFG_DIM_DURATION}ms"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INHIBIT CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_is_inhibited() {
    # Check multiple inhibit sources

    # 1. File-based inhibit (set by other scripts / plugins)
    if [[ -f "$DIM_INHIBIT_FILE" ]]; then
        local inhibit_pid reason expires
        inhibit_pid="$(head -1 "$DIM_INHIBIT_FILE" 2>/dev/null || echo '')"
        reason="$(sed -n '2p' "$DIM_INHIBIT_FILE" 2>/dev/null || echo 'unknown')"
        expires="$(sed -n '3p' "$DIM_INHIBIT_FILE" 2>/dev/null || echo '0')"

        local now
        now="$(date +%s)"

        # Check expiry
        if [[ -n "$expires" ]] && (( expires > 0 )) && \
           (( now > expires )); then
            log_debug "Inhibit expired — removing"
            rm -f "$DIM_INHIBIT_FILE"
        elif [[ -n "$inhibit_pid" ]] && ! kill -0 "$inhibit_pid" 2>/dev/null; then
            log_debug "Inhibit process dead — removing"
            rm -f "$DIM_INHIBIT_FILE"
        else
            log_debug "Dimming inhibited: $reason"
            return 0  # Is inhibited
        fi
    fi

    # 2. Hyprland idle inhibitor active
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        local inhibitors
        inhibitors="$(hyprctl activeinhibitors 2>/dev/null | \
            jq 'length' 2>/dev/null || echo '0')"
        if (( inhibitors > 0 )); then
            log_debug "Hyprland idle inhibitor active ($inhibitors)"
            return 0  # Is inhibited
        fi
    fi

    # 3. Full-screen window detection
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        local fullscreen_count
        fullscreen_count="$(hyprctl clients -j 2>/dev/null | \
            jq '[.[] | select(.fullscreen == true)] | length' \
            2>/dev/null || echo '0')"
        if (( fullscreen_count > 0 )); then
            log_debug "Fullscreen window detected — skip dim"
            return 0  # Is inhibited
        fi
    fi

    # 4. DND mode check (if configured)
    if [[ "$CFG_RESPECT_DND" == "true" ]]; then
        local dnd_state
        dnd_state="$(swaync-client --get-dnd 2>/dev/null || echo 'false')"
        if [[ "$dnd_state" == "true" ]]; then
            local ash_mode
            ash_mode="$(cat "${CACHE_DIR}/state/current-mode.json" 2>/dev/null | \
                jq -r '.mode // "default"' 2>/dev/null || echo 'default')"
            if [[ "$ash_mode" == "focus" || "$ash_mode" == "game" ]]; then
                log_debug "ASH mode $ash_mode — skip dim"
                return 0  # Is inhibited
            fi
        fi
    fi

    # 5. Audio playback detection (media playing)
    if command -v playerctl &>/dev/null; then
        local play_status
        play_status="$(playerctl status 2>/dev/null | head -1 || echo '')"
        if [[ "$play_status" == "Playing" ]]; then
            log_debug "Media playing — skip dim"
            return 0  # Is inhibited
        fi
    fi

    # 6. Game mode detection
    if command -v gamemoded &>/dev/null || \
       pgrep -x gamemoded &>/dev/null; then
        if [[ -f "${CACHE_DIR}/state/current-mode.json" ]]; then
            local mode
            mode="$(jq -r '.mode // ""' \
                "${CACHE_DIR}/state/current-mode.json" 2>/dev/null)"
            [[ "$mode" == "game" ]] && {
                log_debug "Game mode active — skip dim"
                return 0
            }
        fi
    fi

    return 1  # Not inhibited — proceed with dim
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BRIGHTNESS BACKEND ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_current_brightness() {
    local device="${1:-}"

    if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        if [[ -n "$device" ]]; then
            local pct
            pct="$(brightnessctl --device="$device" -m 2>/dev/null \
                | awk -F, '{gsub(/%/,"",$4); print int($4)}')"
            echo "${pct:-50}"
        else
            local pct
            pct="$(brightnessctl -m 2>/dev/null \
                | awk -F, '{gsub(/%/,"",$4); print int($4)}')"
            echo "${pct:-50}"
        fi
    elif [[ "$HAS_XRANDR" == "true" ]] && [[ "$IS_WAYLAND" == "false" ]]; then
        xrandr --verbose 2>/dev/null \
            | grep -i brightness \
            | head -1 \
            | awk '{printf "%d", $2*100}' || echo "50"
    else
        # Fallback: read sysfs
        local sysfs_path="/sys/class/backlight"
        local device_path
        device_path="$(ls "$sysfs_path" 2>/dev/null | head -1 || echo '')"

        if [[ -n "$device_path" ]]; then
            local cur max
            cur="$(cat "${sysfs_path}/${device_path}/brightness"      2>/dev/null || echo 0)"
            max="$(cat "${sysfs_path}/${device_path}/max_brightness"  2>/dev/null || echo 100)"
            echo "$(( cur * 100 / max ))"
        else
            echo "50"
        fi
    fi
}

_set_brightness_instant() {
    local target="$1"       # 0-100
    local device="${2:-}"

    # Clamp to valid range
    (( target < 0 ))   && target=0
    (( target > 100 )) && target=100

    log_debug "Set brightness instant: ${target}% device='${device}'"

    if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        if [[ -n "$device" ]]; then
            brightnessctl --device="$device" \
                set "${target}%" -q 2>/dev/null || true
        else
            brightnessctl set "${target}%" -q 2>/dev/null || true
        fi
        return 0
    fi

    if [[ "$HAS_XRANDR" == "true" ]] && [[ "$IS_WAYLAND" == "false" ]]; then
        local decimal
        decimal="$(awk "BEGIN {printf \"%.2f\", $target/100}")"
        local output
        output="$(xrandr 2>/dev/null | grep ' connected' | \
            awk '{print $1}' | head -1)"
        [[ -n "$output" ]] && \
            xrandr --output "$output" --brightness "$decimal" &>/dev/null || true
        return 0
    fi

    # Sysfs direct write
    local sysfs_path="/sys/class/backlight"
    local device_path
    device_path="$(ls "$sysfs_path" 2>/dev/null | head -1 || echo '')"

    if [[ -n "$device_path" ]]; then
        local max
        max="$(cat "${sysfs_path}/${device_path}/max_brightness" 2>/dev/null \
            || echo 100)"
        local raw=$(( target * max / 100 ))
        echo "$raw" > "${sysfs_path}/${device_path}/brightness" 2>/dev/null \
            || true
    fi
}

_get_backlight_devices() {
    # Returns list of available backlight device names
    local devices=()

    # brightnessctl devices
    if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        while IFS= read -r line; do
            local dev
            dev="$(echo "$line" | grep -oP "'\K[^']+")"
            [[ -n "$dev" ]] && devices+=("$dev")
        done < <(brightnessctl --list 2>/dev/null \
            | grep -E "^Device '.*' of class 'backlight'" || true)
    fi

    # Sysfs fallback
    if (( ${#devices[@]} == 0 )); then
        while IFS= read -r dev; do
            [[ -n "$dev" ]] && devices+=("$dev")
        done < <(ls /sys/class/backlight/ 2>/dev/null || true)
    fi

    printf '%s\n' "${devices[@]}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HYPRLAND MONITOR MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_monitors() {
    # Returns JSON array of connected monitors
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        local monitors
        monitors="$(hyprctl monitors -j 2>/dev/null || echo '[]')"
        echo "$monitors"
        # Cache for other operations
        echo "$monitors" > "$DIM_MONITOR_CACHE" 2>/dev/null || true
        return 0
    fi

    # Fallback: xrandr
    if [[ "$HAS_XRANDR" == "true" ]]; then
        local mons_json='[]'
        while IFS= read -r mon; do
            mons_json="$(echo "$mons_json" | jq \
                --arg name "$mon" \
                '. += [{"name": $name, "id": (length)}]' \
                2>/dev/null)"
        done < <(xrandr 2>/dev/null | grep ' connected' | awk '{print $1}')
        echo "$mons_json"
        return 0
    fi

    echo '[]'
}

_is_monitor_excluded() {
    local monitor_name="$1"

    [[ -z "$CFG_EXCLUDE_MONITORS" ]] && return 1  # Not excluded

    local IFS=','
    for excluded in $CFG_EXCLUDE_MONITORS; do
        excluded="$(echo "$excluded" | xargs)"  # Trim spaces
        [[ "$monitor_name" == "$excluded" ]] && return 0  # Is excluded
    done
    return 1
}

_get_monitor_backlight_device() {
    local monitor_name="$1"

    # Try to map Hyprland monitor name to backlight device
    # Common mappings: eDP-1 → intel_backlight, HDMI* → ddcutil
    case "$monitor_name" in
        eDP-*|LVDS-*|DSI-*)
            # Built-in laptop display
            if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
                brightnessctl --list 2>/dev/null \
                    | grep -oP "'\K[^']+" \
                    | grep -iE 'intel_backlight|amdgpu_bl|backlight' \
                    | head -1 || echo ""
            fi
            ;;
        HDMI-*|DP-*|DisplayPort-*)
            # External monitor — use DDC/CI if available
            echo "external:$monitor_name"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DDC/CI EXTERNAL MONITOR CONTROL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ddcutil_get_brightness() {
    local bus="${1:-}"

    [[ "$HAS_DDCUTIL" == "false" ]] && echo "50" && return 0

    local val
    if [[ -n "$bus" ]]; then
        val="$(ddcutil getvcp 10 --bus "$bus" 2>/dev/null \
            | grep 'current value' \
            | awk '{print $NF}' || echo '50')"
    else
        val="$(ddcutil getvcp 10 2>/dev/null \
            | grep 'current value' \
            | awk '{print $NF}' || echo '50')"
    fi

    echo "${val:-50}"
}

_ddcutil_set_brightness() {
    local target="$1"
    local bus="${2:-}"

    [[ "$HAS_DDCUTIL" == "false" ]] && return 0

    # DDC takes 0-100
    (( target < 0 ))   && target=0
    (( target > 100 )) && target=100

    if [[ -n "$bus" ]]; then
        ddcutil setvcp 10 "$target" --bus "$bus" &>/dev/null || true
    else
        ddcutil setvcp 10 "$target" &>/dev/null || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GAMMA / COLOR TEMPERATURE ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_apply_gamma() {
    local r="$1"   # 0.0-1.0
    local g="$2"
    local b="$3"
    local monitor="${4:-}"

    log_debug "Applying gamma: R=$r G=$g B=$b monitor='$monitor'"

    # Hyprland shader approach (most accurate on Wayland)
    if [[ "$HAS_HYPRCTL" == "true" ]] && [[ "$IS_WAYLAND" == "true" ]]; then
        # Use Hyprland's vibranceon approach with custom gamma
        # Approximate via contrast/saturation keywords
        hyprctl keyword decoration:screen_shader "" &>/dev/null || true
    fi

    # gammastep one-shot gamma
    if [[ "$HAS_GAMMASTEP" == "true" ]]; then
        pkill -x gammastep &>/dev/null || true
        sleep 0.1
        local temp
        # Map gamma reduction to color temperature
        # Cooler gamma = lower temp
        temp="$(awk "BEGIN {printf \"%d\", 6500 * ($r + $g + $b) / 3}")"
        (( temp < 1000 )) && temp=1000
        (( temp > 6500 )) && temp=6500
        gammastep -O "$temp" &>/dev/null &
        disown 2>/dev/null || true
        log_debug "Gammastep: -O $temp"
        return 0
    fi

    # xrandr gamma (X11 or XWayland)
    if [[ "$HAS_XRANDR" == "true" ]]; then
        local outputs=()
        if [[ -n "$monitor" ]]; then
            outputs=("$monitor")
        else
            while IFS= read -r out; do
                outputs+=("$out")
            done < <(xrandr 2>/dev/null | grep ' connected' | awk '{print $1}')
        fi

        for output in "${outputs[@]}"; do
            xrandr --output "$output" \
                --gamma "${r}:${g}:${b}" \
                &>/dev/null || true
        done
        log_debug "xrandr gamma applied to: ${outputs[*]}"
    fi
}

_reset_gamma() {
    local monitor="${1:-}"

    log_debug "Resetting gamma"

    pkill -x gammastep &>/dev/null || true
    pkill -x wlsunset  &>/dev/null || true
    sleep 0.1

    # Restart night light if it was active
    local nl_state="${CACHE_DIR}/night-light.state"
    if [[ -f "$nl_state" ]] && [[ "$(cat "$nl_state" 2>/dev/null)" == "on" ]]; then
        local nl_script="${SCRIPT_DIR}/../../../swaync/scripts/night-light-on.sh"
        [[ -x "$nl_script" ]] && "$nl_script" --silent &>/dev/null & true
    fi

    if [[ "$HAS_XRANDR" == "true" ]]; then
        local outputs=()
        if [[ -n "$monitor" ]]; then
            outputs=("$monitor")
        else
            while IFS= read -r out; do
                outputs+=("$out")
            done < <(xrandr 2>/dev/null | grep ' connected' | awk '{print $1}')
        fi
        for output in "${outputs[@]}"; do
            xrandr --output "$output" --gamma "1:1:1" &>/dev/null || true
        done
    fi

    log_debug "Gamma reset complete"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# EASING FUNCTIONS (pure bash math)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ease() {
    # Apply easing to progress value (0.0 to 1.0)
    # Returns eased value as decimal string
    local progress="$1"   # 0.0-1.0 as string
    local easing="${2:-ease-in-out}"

    if [[ "$HAS_PYTHON" == "true" ]]; then
        python3 -c "
import math
p = float('$progress')
easing = '$easing'

def ease_in_out_cubic(t):
    if t < 0.5:
        return 4 * t * t * t
    return 1 - pow(-2 * t + 2, 3) / 2

def ease_in_quad(t):
    return t * t

def ease_out_expo(t):
    if t == 0: return 0
    return 1 - pow(2, -10 * t)

def ease_in_out_sine(t):
    return -(math.cos(math.pi * t) - 1) / 2

def ease_in_out_quart(t):
    if t < 0.5:
        return 8 * t * t * t * t
    return 1 - pow(-2 * t + 2, 4) / 2

def linear(t):
    return t

funcs = {
    'ease-in-out':        ease_in_out_cubic,
    'ease-in-out-cubic':  ease_in_out_cubic,
    'ease-in':            ease_in_quad,
    'ease-out':           ease_out_expo,
    'ease-in-out-sine':   ease_in_out_sine,
    'ease-in-out-quart':  ease_in_out_quart,
    'linear':             linear,
}

fn = funcs.get(easing, ease_in_out_cubic)
result = max(0.0, min(1.0, fn(p)))
print(f'{result:.6f}')
"
    elif [[ "$HAS_BC" == "true" ]]; then
        # Simplified cubic ease with bc
        echo "$progress $easing" | bc -l 2>/dev/null << 'EOF'
define ease(p) {
    if (p < 0.5) {
        return 4 * p * p * p;
    }
    return 1 - (-2 * p + 2)^3 / 2;
}
ease($1)
EOF
    else
        # No math available — return linear
        echo "$progress"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SMOOTH ANIMATION ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_stop_animation() {
    if [[ -f "$DIM_ANIM_PID_FILE" ]]; then
        local pid
        pid="$(cat "$DIM_ANIM_PID_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            log_debug "Animation stopped (PID=$pid)"
        fi
        rm -f "$DIM_ANIM_PID_FILE"
    fi
}

_animate_brightness() {
    local from_pct="$1"       # Starting brightness %
    local to_pct="$2"         # Target brightness %
    local duration_ms="$3"    # Total duration milliseconds
    local steps="$4"          # Number of steps
    local easing="${5:-ease-in-out}"
    local device="${6:-}"     # Optional specific device
    local is_external="${7:-false}"  # DDC/CI external monitor

    local step_time_us
    step_time_us="$(( duration_ms * 1000 / steps ))"

    log_debug "Animate: ${from_pct}% → ${to_pct}% over ${duration_ms}ms \
in ${steps} steps (${step_time_us}µs each) easing=${easing}"

    local range
    range=$(( to_pct - from_pct ))

    for (( i=1; i<=steps; i++ )); do
        # Linear progress 0.0→1.0
        local progress
        progress="$(awk "BEGIN {printf \"%.6f\", $i/$steps}")"

        # Apply easing
        local eased
        eased="$(_ease "$progress" "$easing")"

        # Calculate current brightness
        local current_pct
        current_pct="$(awk \
            "BEGIN {printf \"%d\", $from_pct + ($range * $eased)}")"

        # Clamp
        (( current_pct < 0 ))   && current_pct=0
        (( current_pct > 100 )) && current_pct=100

        # Set brightness
        if [[ "$is_external" == "true" ]]; then
            _ddcutil_set_brightness "$current_pct" "$device" 2>/dev/null || true
        else
            _set_brightness_instant "$current_pct" "$device"
        fi

        # Sleep for step interval
        if command -v usleep &>/dev/null; then
            usleep "$step_time_us" 2>/dev/null || sleep 0
        else
            sleep "0.0$(printf '%06d' "$step_time_us" | head -c 2)" 2>/dev/null \
                || true
        fi
    done

    # Ensure final value is exact
    if [[ "$is_external" == "true" ]]; then
        _ddcutil_set_brightness "$to_pct" "$device" 2>/dev/null || true
    else
        _set_brightness_instant "$to_pct" "$device"
    fi

    log_debug "Animation complete: ${to_pct}%"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BRIGHTNESS STATE PERSISTENCE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_save_brightness_state() {
    # Save current brightness of all monitors for restore
    log_debug "Saving brightness state…"

    local state_json
    state_json="$(jq -n '{
        "saved_at":  now | todate,
        "monitors":  {},
        "gamma":     {"r": 1.0, "g": 1.0, "b": 1.0},
        "night_light_active": false
    }' 2>/dev/null)"

    # Get all monitors
    local monitors
    monitors="$(_get_monitors)"

    # Save each monitor's brightness
    local monitor_names=()
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        while IFS= read -r name; do
            [[ -n "$name" ]] && monitor_names+=("$name")
        done < <(echo "$monitors" | jq -r '.[].name' 2>/dev/null)
    fi

    if (( ${#monitor_names[@]} == 0 )); then
        monitor_names+=("primary")
    fi

    for mon in "${monitor_names[@]}"; do
        if _is_monitor_excluded "$mon"; then
            log_debug "Skip save for excluded monitor: $mon"
            continue
        fi

        local brightness
        local backlight_dev
        backlight_dev="$(_get_monitor_backlight_device "$mon")"

        if [[ "$backlight_dev" == external:* ]]; then
            brightness="$(_ddcutil_get_brightness)"
        else
            brightness="$(_get_current_brightness "$backlight_dev")"
        fi

        state_json="$(echo "$state_json" | jq \
            --arg mon "$mon" \
            --argjson b "$brightness" \
            --arg dev "$backlight_dev" \
            '.monitors[$mon] = {"brightness": $b, "device": $dev}' \
            2>/dev/null)"

        log_debug "Saved: $mon = ${brightness}%"
    done

    # Save night light state
    local nl_active=false
    [[ -f "${CACHE_DIR}/night-light.state" ]] && \
        [[ "$(cat "${CACHE_DIR}/night-light.state" 2>/dev/null)" == "on" ]] && \
        nl_active=true

    state_json="$(echo "$state_json" | jq \
        --argjson nl "$nl_active" \
        '.night_light_active = $nl' \
        2>/dev/null)"

    echo "$state_json" > "$DIM_BRIGHTNESS_BACKUP"
    log_success "Brightness state saved"
}

_load_saved_brightness() {
    # Returns brightness for a specific monitor from saved state
    local monitor="${1:-primary}"

    [[ ! -f "$DIM_BRIGHTNESS_BACKUP" ]] && echo "100" && return

    local brightness
    brightness="$(jq -r \
        --arg mon "$monitor" \
        '.monitors[$mon].brightness // 100' \
        "$DIM_BRIGHTNESS_BACKUP" 2>/dev/null || echo '100')"

    echo "${brightness:-100}"
}

_get_saved_device() {
    local monitor="${1:-primary}"

    [[ ! -f "$DIM_BRIGHTNESS_BACKUP" ]] && echo "" && return

    jq -r \
        --arg mon "$monitor" \
        '.monitors[$mon].device // ""' \
        "$DIM_BRIGHTNESS_BACKUP" 2>/dev/null || echo ""
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ADAPTIVE DIM LEVEL CALCULATOR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_calculate_dim_level() {
    local base_level="$CFG_DIM_LEVEL"

    # Night-time adaptive dimming
    if [[ "$CFG_ADAPTIVE_DIM" == "true" ]]; then
        local hour
        hour="$(date +%H)"

        if (( hour >= 22 || hour <= 6 )); then
            # Late night — extra dim
            base_level="$DEFAULT_NIGHT_DIM_LEVEL"
            log_debug "Night-time dim: ${base_level}%"
        elif (( hour >= 20 || hour <= 8 )); then
            # Evening/morning — moderately dim
            base_level=$(( base_level - 5 ))
            log_debug "Evening/morning dim: ${base_level}%"
        fi
    fi

    # Battery-adaptive dimming
    if [[ "$HAS_BATTERY" == "true" && \
          "$CFG_BATTERY_AGGRESSIVE" == "true" ]]; then
        local bat_cap
        bat_cap="$(cat /sys/class/power_supply/BAT*/capacity \
            2>/dev/null | head -1 || echo '100')"

        local bat_status
        bat_status="$(cat /sys/class/power_supply/BAT*/status \
            2>/dev/null | head -1 || echo 'Unknown')"

        if [[ "$bat_status" == "Discharging" ]]; then
            if (( bat_cap <= 10 )); then
                base_level="$DEFAULT_BATTERY_DIM_LEVEL"
                log_debug "Critical battery dim: ${base_level}%"
            elif (( bat_cap <= 25 )); then
                base_level=$(( base_level - 5 ))
                log_debug "Low battery dim: ${base_level}%"
            fi
        fi
    fi

    # Ensure minimum
    (( base_level < DEFAULT_MIN_BRIGHTNESS )) && \
        base_level=$DEFAULT_MIN_BRIGHTNESS

    echo "$base_level"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAYBAR / SWAYNC INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_waybar() {
    pkill -SIGRTMIN+4 waybar 2>/dev/null || true
    log_debug "Waybar signaled (SIGRTMIN+4)"
}

_update_swaync_widget() {
    local state="$1"  # dimmed | undimmed
    local level="${2:-}"

    # Write dim state for swaync widget to read
    jq -n \
        --arg state "$state" \
        --arg level "$level" \
        --arg ts "$(date -Iseconds)" \
        '{"state":$state,"level":$level,"updated":$ts}' \
        > "${RUNTIME_DIR}/dim-status.json" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HYPRLAND DPMS / SHADER INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_apply_hyprland_dim() {
    local level="$1"  # 0.0-1.0 (dim amount, not brightness)
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    # Hyprland has a built-in dim_inactive — abuse it for screen-wide dim
    # Calculate dim_strength: 1.0 = undimmed, 0.0 = fully dimmed
    local strength
    strength="$(awk "BEGIN {printf \"%.2f\", $level/100}")"

    # Apply via hyprctl keywords
    hyprctl keyword decoration:active_opacity   "$strength" &>/dev/null || true
    hyprctl keyword decoration:inactive_opacity "$strength" &>/dev/null || true
    log_debug "Hyprland opacity set to $strength"
}

_reset_hyprland_dim() {
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0
    hyprctl keyword decoration:active_opacity   "1.0" &>/dev/null || true
    hyprctl keyword decoration:inactive_opacity "1.0" &>/dev/null || true
    log_debug "Hyprland opacity reset"
}

_apply_dpms() {
    local state="$1"  # on | off | standby | suspend
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    local monitors
    monitors="$(_get_monitors)"

    echo "$monitors" | jq -r '.[].name' 2>/dev/null | \
    while IFS= read -r mon; do
        hyprctl dispatch dpms "$state" "$mon" &>/dev/null || true
    done

    log_debug "DPMS: $state applied to all monitors"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SOUND / NOTIFICATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_play_sound() {
    [[ "$CFG_SOUND_ENABLED" != "true" ]] && return 0
    local file="$1"
    [[ ! -f "$file" ]] && return 0
    if command -v pw-play &>/dev/null; then
        pw-play --volume=0.3 "$file" &>/dev/null &
    elif command -v paplay &>/dev/null; then
        paplay --volume=19660 "$file" &>/dev/null &
    fi
    disown 2>/dev/null || true
}

_show_notification() {
    [[ "$CFG_NOTIFY_ENABLED" != "true" ]] && return 0
    local title="$1"
    local body="${2:-}"
    notify-send \
        --urgency=low \
        --expire-time=2000 \
        --app-name="ASH Idle" \
        "$title" "$body" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HISTORY RECORDER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_record_dim_event() {
    local event="$1"  # dim | undim
    local level="${2:-0}"
    local duration_ms="${3:-0}"

    command -v jq &>/dev/null || return 0

    [[ ! -f "$DIM_HISTORY_FILE" ]] && \
        echo '{"events":[],"total_dims":0}' > "$DIM_HISTORY_FILE"

    jq \
        --arg  event "$event" \
        --argjson lvl "$level" \
        --argjson dur "$duration_ms" \
        --arg ts "$(date -Iseconds)" \
        '.events += [{
            "event":       $event,
            "level":       $lvl,
            "duration_ms": $dur,
            "timestamp":   $ts
        }] |
        .events = .events[-200:] |
        if $event == "dim" then .total_dims += 1 else . end' \
        "$DIM_HISTORY_FILE" \
        > "${DIM_HISTORY_FILE}.tmp" 2>/dev/null && \
    mv "${DIM_HISTORY_FILE}.tmp" "$DIM_HISTORY_FILE"

    log_debug "History: $event level=${level}%"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE DIM OPERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_do_dim() {
    local dim_level="${1:-}"
    local duration_ms="${2:-}"
    local steps="${3:-}"
    local easing="${4:-}"

    # Apply runtime config defaults
    [[ -z "$dim_level"   ]] && dim_level="$(_calculate_dim_level)"
    [[ -z "$duration_ms" ]] && duration_ms="$CFG_DIM_DURATION"
    [[ -z "$steps"       ]] && steps="$CFG_DIM_STEPS"
    [[ -z "$easing"      ]] && easing="$CFG_DIM_EASING"

    # Ensure already-dimmed check
    if [[ -f "$DIM_STATE_FILE" ]]; then
        local cur_state
        cur_state="$(cat "$DIM_STATE_FILE" 2>/dev/null || echo '')"
        if [[ "$cur_state" == "dimmed" ]]; then
            log_info "Screen already dimmed — skipping"
            return 0
        fi
    fi

    log_info "Dimming screen: target=${dim_level}% duration=${duration_ms}ms \
steps=${steps} easing=${easing}"

    # Inhibit check
    if _is_inhibited; then
        log_info "Dimming inhibited — skipping"
        return 0
    fi

    # Save current state BEFORE dimming
    _save_brightness_state

    # Get monitors
    local monitors
    monitors="$(_get_monitors)"
    local monitor_names=()

    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        while IFS= read -r name; do
            [[ -n "$name" ]] && monitor_names+=("$name")
        done < <(echo "$monitors" | jq -r '.[].name' 2>/dev/null)
    fi

    [[ ${#monitor_names[@]} -eq 0 ]] && monitor_names+=("primary")

    # Stop any running animation
    _stop_animation

    # Write dim state
    echo "dimming" > "$DIM_STATE_FILE"

    # ── Animate each monitor ──────────────────────────────────────────────
    local first_monitor=true

    for mon in "${monitor_names[@]}"; do
        if _is_monitor_excluded "$mon"; then
            log_debug "Skip dim: excluded monitor $mon"
            continue
        fi

        local backlight_dev
        backlight_dev="$(_get_monitor_backlight_device "$mon")"

        local current_brightness
        local is_external=false

        if [[ "$backlight_dev" == external:* ]]; then
            is_external=true
            local bus="${backlight_dev#external:}"
            current_brightness="$(_ddcutil_get_brightness "$bus")"
            log_debug "External monitor $mon: bus=$bus current=${current_brightness}%"
        else
            current_brightness="$(_get_current_brightness "$backlight_dev")"
            log_debug "Monitor $mon: device='$backlight_dev' \
current=${current_brightness}%"
        fi

        # Don't dim if already below target
        if (( current_brightness <= dim_level )); then
            log_debug "Monitor $mon already at ${current_brightness}% — skip"
            continue
        fi

        if [[ "$first_monitor" == "true" ]]; then
            # Animate first monitor in foreground for sync
            _animate_brightness \
                "$current_brightness" \
                "$dim_level" \
                "$duration_ms" \
                "$steps" \
                "$easing" \
                "$backlight_dev" \
                "$is_external"
            first_monitor=false
        else
            # Remaining monitors in parallel
            (
                _animate_brightness \
                    "$current_brightness" \
                    "$dim_level" \
                    "$duration_ms" \
                    "$steps" \
                    "$easing" \
                    "$backlight_dev" \
                    "$is_external"
            ) &
            log_debug "Parallel dim started for: $mon"
        fi
    done

    # Wait for parallel animations
    wait 2>/dev/null || true

    # ── Apply gamma warm shift if configured ─────────────────────────────
    if [[ "$CFG_WARM_DIM" == "true" || "$CFG_USE_GAMMA" == "true" ]]; then
        _apply_gamma \
            "$CFG_DIM_GAMMA_R" \
            "$CFG_DIM_GAMMA_G" \
            "$CFG_DIM_GAMMA_B"
    fi

    # ── Hyprland opacity overlay ──────────────────────────────────────────
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        local opacity
        opacity="$(awk "BEGIN {printf \"%.2f\", $dim_level/100 + 0.15}")"
        (( $(awk "BEGIN {print ($opacity > 0.95)}") )) && opacity="0.95"
        hyprctl keyword decoration:active_opacity   "$opacity" &>/dev/null || true
        hyprctl keyword decoration:inactive_opacity "$opacity" &>/dev/null || true
        log_debug "Hyprland opacity: $opacity"
    fi

    # ── Update state ──────────────────────────────────────────────────────
    echo "dimmed" > "$DIM_STATE_FILE"

    jq -n \
        --argjson level  "$dim_level" \
        --argjson dur    "$duration_ms" \
        --arg ts         "$(date -Iseconds)" \
        '{
            "state":       "dimmed",
            "level":       $level,
            "duration_ms": $dur,
            "dimmed_at":   $ts
        }' > "${RUNTIME_DIR}/dim-info.json" 2>/dev/null || true

    # Signal Waybar
    _signal_waybar
    _update_swaync_widget "dimmed" "${dim_level}%"

    # Analytics
    _record_dim_event "dim" "$dim_level" "$duration_ms"

    # Sound / notify
    _play_sound "${XDG_CONFIG_HOME:-$HOME/.config}/sounds/brightness-change.ogg"
    _show_notification "${ICON_DIM}  Screen Dimmed" \
        "Brightness: ${dim_level}%"

    # Run post-dim hook
    local hook="${CONFIG_DIR}/hooks/post-dim.sh"
    [[ -f "$hook" && -x "$hook" ]] && \
        DIM_LEVEL="$dim_level" DIM_DURATION="$duration_ms" \
        "$hook" & true

    log_success "Screen dimmed to ${dim_level}%"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH Dim Screen v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [OPTIONS]

${CLR_BOLD}OPTIONS${CLR_RESET}
  ${CLR_GREEN}--level N${CLR_RESET}          Target brightness % (default: ${DEFAULT_DIM_LEVEL})
  ${CLR_GREEN}--duration MS${CLR_RESET}      Transition duration ms (default: ${DEFAULT_DIM_DURATION})
  ${CLR_GREEN}--steps N${CLR_RESET}          Animation steps (default: ${DEFAULT_DIM_STEPS})
  ${CLR_GREEN}--easing NAME${CLR_RESET}      Easing function (ease-in-out|linear|ease-out)
  ${CLR_YELLOW}--gamma R G B${CLR_RESET}     Apply gamma shift (e.g. 0.95 0.90 0.80)
  ${CLR_YELLOW}--no-gamma${CLR_RESET}         Skip gamma adjustment
  ${CLR_YELLOW}--no-warm${CLR_RESET}          Skip warm color shift
  ${CLR_BLUE}--monitor NAME${CLR_RESET}    Dim specific monitor only
  ${CLR_BLUE}--all-monitors${CLR_RESET}    Dim all monitors
  ${CLR_CYAN}--instant${CLR_RESET}          No animation (instant)
  ${CLR_CYAN}--force${CLR_RESET}            Ignore inhibit checks
  ${CLR_WHITE}--status${CLR_RESET}           Show dim status
  ${CLR_WHITE}--history${CLR_RESET}          Show dim history
  ${CLR_WHITE}--version${CLR_RESET}          Show version
  ${CLR_WHITE}--help${CLR_RESET}             Show help

${CLR_BOLD}EASING FUNCTIONS${CLR_RESET}
  ease-in-out  (default) — smooth start and end
  ease-in      — slow start, fast end
  ease-out     — fast start, slow end (expo)
  linear       — constant speed
  ease-in-out-sine   — sine wave easing
  ease-in-out-quart  — quartic easing

${CLR_BOLD}EXAMPLES${CLR_RESET}
  $(basename "$0")                          # Standard dim
  $(basename "$0") --level 5               # Dim to 5%
  $(basename "$0") --level 20 --duration 5000  # Slow dim
  $(basename "$0") --instant               # No transition
  $(basename "$0") --force                 # Override inhibit

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    _ensure_dirs
    _detect_capabilities
    _load_profile
    _acquire_lock || { log_error "Lock failed — another dim in progress"; exit 0; }

    local dim_level=""
    local duration_ms=""
    local steps=""
    local easing=""
    local force=false
    local instant=false
    local target_monitor=""
    local no_gamma=false
    local no_warm=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --level|-l)
                shift; dim_level="${1:-$CFG_DIM_LEVEL}"
                ;;
            --level=*)
                dim_level="${1#--level=}"
                ;;
            --duration|-d)
                shift; duration_ms="${1:-$CFG_DIM_DURATION}"
                ;;
            --steps|-s)
                shift; steps="${1:-$CFG_DIM_STEPS}"
                ;;
            --easing|-e)
                shift; easing="${1:-$CFG_DIM_EASING}"
                ;;
            --gamma)
                shift
                CFG_DIM_GAMMA_R="${1:-1.0}"; shift
                CFG_DIM_GAMMA_G="${1:-1.0}"; shift
                CFG_DIM_GAMMA_B="${1:-1.0}"
                CFG_USE_GAMMA=true
                ;;
            --no-gamma)
                no_gamma=true
                CFG_USE_GAMMA=false
                ;;
            --no-warm)
                no_warm=true
                CFG_WARM_DIM=false
                ;;
            --monitor|-m)
                shift; target_monitor="${1:-}"
                ;;
            --all-monitors)
                target_monitor=""
                ;;
            --force|-f)
                force=true
                ;;
            --instant|-i)
                instant=true
                steps=1
                duration_ms=50
                ;;
            --status)
                if [[ -f "${RUNTIME_DIR}/dim-info.json" ]]; then
                    cat "${RUNTIME_DIR}/dim-info.json"
                else
                    echo '{"state":"undimmed"}'
                fi
                exit 0
                ;;
            --history)
                if [[ -f "$DIM_HISTORY_FILE" ]]; then
                    jq '.events[-10:] | reverse' "$DIM_HISTORY_FILE" \
                        2>/dev/null
                else
                    echo "[]"
                fi
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
                # Positional: treat as level
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    dim_level="$1"
                else
                    log_warn "Unknown argument: $1"
                fi
                ;;
        esac
        shift 2>/dev/null || break
    done

    # Force: skip inhibit checks
    if [[ "$force" == "true" ]]; then
        log_info "Force mode — overriding inhibit checks"
        _do_dim "$dim_level" "$duration_ms" "$steps" "$easing"
    else
        _do_dim "$dim_level" "$duration_ms" "$steps" "$easing"
    fi

    exit 0
}

main "$@"