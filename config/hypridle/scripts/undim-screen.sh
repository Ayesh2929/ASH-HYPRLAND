#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HyprIdle Ultra Undim Screen Script               ║
# ║  Premium screen restore engine with smooth brightness recovery,              ║
# ║  per-monitor precision restore, gamma reset, HDR re-enable,                  ║
# ║  night-light restoration, state validation, and hook system                  ║
# ║                                                                              ║
# ║  Author  : ash-dotfiles                                                      ║
# ║  Version : 5.0.0                                                             ║
# ║  License : MIT                                                               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail
IFS=$'\n\t'

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CONSTANTS & PATHS (mirrored from dim-screen.sh)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

readonly SCRIPT_NAME="ash-undim-screen"
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"

# Shared state files from dim-screen.sh
readonly DIM_STATE_FILE="${RUNTIME_DIR}/dim.state"
readonly DIM_LOCK_FILE="${RUNTIME_DIR}/dim.lock"
readonly DIM_BRIGHTNESS_BACKUP="${RUNTIME_DIR}/brightness-backup.json"
readonly DIM_ANIM_PID_FILE="${RUNTIME_DIR}/dim-anim.pid"
readonly DIM_PROFILE_FILE="${CONFIG_DIR}/dim-profile.json"
readonly DIM_MONITOR_CACHE="${RUNTIME_DIR}/monitors.json"
readonly DIM_HISTORY_FILE="${CACHE_DIR}/dim-history.json"
readonly DIM_INHIBIT_FILE="${RUNTIME_DIR}/dim-inhibit"
readonly UNDIM_LOCK_FILE="${RUNTIME_DIR}/undim.lock"
readonly UNDIM_LOG_FILE="${CACHE_DIR}/logs/undim-screen.log"
readonly UNDIM_HISTORY_FILE="${CACHE_DIR}/undim-history.json"

# Sound
readonly SOUND_UNDIM="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/brightness-change.ogg"
readonly SOUND_WAKEUP="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/notification.ogg"

# Icons
readonly ICON_DIM="󰃞"
readonly ICON_BRIGHT="󰃠"
readonly ICON_SUN="󰖙"
readonly ICON_MONITOR="󰍹"
readonly ICON_ASH="󱎫"
readonly ICON_RESTORE="󰑓"
readonly ICON_WAKE="󰖙"

# Colors
readonly CLR_RESET=$'\033[0m'
readonly CLR_BOLD=$'\033[1m'
readonly CLR_RED=$'\033[0;31m'
readonly CLR_GREEN=$'\033[0;32m'
readonly CLR_YELLOW=$'\033[0;33m'
readonly CLR_CYAN=$'\033[0;36m'
readonly CLR_GRAY=$'\033[0;90m'
readonly CLR_WHITE=$'\033[0;37m'

# Undim defaults
readonly DEFAULT_UNDIM_DURATION=1500    # ms — faster restore feels snappier
readonly DEFAULT_UNDIM_STEPS=45
readonly DEFAULT_UNDIM_EASING="ease-out"
readonly DEFAULT_FALLBACK_BRIGHTNESS=80 # If no save state found
readonly DEFAULT_MAX_BRIGHTNESS=100

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR" "$STATE_DIR"
        "$CONFIG_DIR" "$RUNTIME_DIR"
        "${CACHE_DIR}/logs"
    )
    for dir in "${dirs[@]}"; do
        [[ -d "$dir" ]] || mkdir -p "$dir"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOGGING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_log() {
    local level="$1"; shift
    local message="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S.%3N')"

    echo "[$timestamp] [$$] [$level] $message" \
        >> "$UNDIM_LOG_FILE" 2>/dev/null || true

    # Rotation 256KB
    if [[ -f "$UNDIM_LOG_FILE" ]]; then
        local sz
        sz="$(stat -c%s "$UNDIM_LOG_FILE" 2>/dev/null || echo 0)"
        (( sz > 262144 )) && \
            mv "$UNDIM_LOG_FILE" \
               "${UNDIM_LOG_FILE}.$(date +%Y%m%d_%H%M%S).old"
    fi

    [[ ! -t 2 ]] && return 0
    case "$level" in
        ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[✗]${CLR_RESET} $message"  >&2 ;;
        WARN)    echo -e "${CLR_YELLOW}[⚠]${CLR_RESET}  $message"          >&2 ;;
        INFO)    echo -e "${CLR_CYAN}[ℹ]${CLR_RESET}  $message"            >&2 ;;
        SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[✓]${CLR_RESET} $message" >&2 ;;
        DEBUG)
            [[ "${ASH_DEBUG:-0}" == "1" ]] && \
                echo -e "${CLR_GRAY}[~] $message${CLR_RESET}" >&2 ;;
    esac
}

log_info()    { _log INFO    "$@"; }
log_warn()    { _log WARN    "$@"; }
log_error()   { _log ERROR   "$@"; }
log_success() { _log SUCCESS "$@"; }
log_debug()   { _log DEBUG   "$@"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOCK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_acquire_lock() {
    local max_wait="${1:-5}"
    local waited=0

    while [[ -f "$UNDIM_LOCK_FILE" ]]; do
        local pid
        pid="$(cat "$UNDIM_LOCK_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            rm -f "$UNDIM_LOCK_FILE"; break
        fi
        (( waited >= max_wait )) && return 1
        sleep 0.2
        (( waited++ )) || true
    done

    echo "$$" > "$UNDIM_LOCK_FILE"
    log_debug "Undim lock acquired (PID=$$)"
    return 0
}

_release_lock() {
    local pid
    pid="$(cat "$UNDIM_LOCK_FILE" 2>/dev/null || echo '')"
    [[ "$pid" == "$$" ]] && rm -f "$UNDIM_LOCK_FILE"
}

_cleanup() {
    _release_lock
    log_debug "Undim cleanup"
}

trap '_cleanup' EXIT INT TERM HUP

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CAPABILITY DETECTION (same as dim-screen.sh)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g HAS_BRIGHTNESSCTL=false
declare -g HAS_XRANDR=false
declare -g HAS_HYPRCTL=false
declare -g HAS_DDCUTIL=false
declare -g HAS_GAMMASTEP=false
declare -g HAS_WLSUNSET=false
declare -g HAS_PYTHON=false
declare -g HAS_BC=false
declare -g IS_WAYLAND=false

_detect_capabilities() {
    command -v brightnessctl &>/dev/null && HAS_BRIGHTNESSCTL=true
    command -v xrandr        &>/dev/null && HAS_XRANDR=true
    command -v hyprctl       &>/dev/null && HAS_HYPRCTL=true
    command -v ddcutil       &>/dev/null && HAS_DDCUTIL=true
    command -v gammastep     &>/dev/null && HAS_GAMMASTEP=true
    command -v wlsunset      &>/dev/null && HAS_WLSUNSET=true
    command -v python3       &>/dev/null && HAS_PYTHON=true
    command -v bc            &>/dev/null && HAS_BC=true

    [[ -n "${WAYLAND_DISPLAY:-}" || \
       -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && IS_WAYLAND=true

    log_debug "Caps: brightnessctl=$HAS_BRIGHTNESSCTL \
hyprctl=$HAS_HYPRCTL ddcutil=$HAS_DDCUTIL wayland=$IS_WAYLAND"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PROFILE LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g CFG_UNDIM_DURATION=$DEFAULT_UNDIM_DURATION
declare -g CFG_UNDIM_STEPS=$DEFAULT_UNDIM_STEPS
declare -g CFG_UNDIM_EASING="$DEFAULT_UNDIM_EASING"
declare -g CFG_RESTORE_EXACT=true
declare -g CFG_RESTORE_GAMMA=true
declare -g CFG_RESTORE_NIGHT_LIGHT=true
declare -g CFG_SOUND_ENABLED=false
declare -g CFG_NOTIFY_ENABLED=false
declare -g CFG_EXCLUDE_MONITORS=""
declare -g CFG_PER_MONITOR=true
declare -g CFG_WAKEUP_BRIGHTNESS_BOOST=false
declare -g CFG_BOOST_AMOUNT=10
declare -g CFG_BOOST_DURATION=400

_load_profile() {
    [[ ! -f "$DIM_PROFILE_FILE" ]] && return 0
    command -v jq &>/dev/null || return 0

    log_debug "Loading undim profile from: $DIM_PROFILE_FILE"

    local get
    get()      { jq -r ".${1} // \"${2}\""  "$DIM_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_num
    get_num()  { jq -r ".${1} // ${2}"      "$DIM_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_bool
    get_bool() {
        jq -r "if .${1} == true then \"true\" else \"false\" end" \
            "$DIM_PROFILE_FILE" 2>/dev/null || echo "$2"
    }

    CFG_UNDIM_DURATION="$(get_num undim_duration_ms $DEFAULT_UNDIM_DURATION)"
    CFG_UNDIM_STEPS="$(get_num   undim_steps        $DEFAULT_UNDIM_STEPS)"
    CFG_UNDIM_EASING="$(get      undim_easing       'ease-out')"
    CFG_RESTORE_EXACT="$(get_bool restore_exact_brightness true)"
    CFG_RESTORE_GAMMA="$(get_bool restore_gamma      true)"
    CFG_RESTORE_NIGHT_LIGHT="$(get_bool restore_night_light true)"
    CFG_SOUND_ENABLED="$(get_bool sound              false)"
    CFG_NOTIFY_ENABLED="$(get_bool notify            false)"
    CFG_EXCLUDE_MONITORS="$(get  exclude_monitors    '')"
    CFG_PER_MONITOR="$(get_bool  per_monitor         true)"
    CFG_WAKEUP_BRIGHTNESS_BOOST="$(get_bool wakeup_brightness_boost false)"
    CFG_BOOST_AMOUNT="$(get_num  boost_amount        10)"
    CFG_BOOST_DURATION="$(get_num boost_duration_ms  400)"

    log_debug "Undim profile: duration=${CFG_UNDIM_DURATION}ms \
easing=${CFG_UNDIM_EASING}"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATE READER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_is_currently_dimmed() {
    if [[ -f "$DIM_STATE_FILE" ]]; then
        local state
        state="$(cat "$DIM_STATE_FILE" 2>/dev/null || echo '')"
        [[ "$state" == "dimmed" || "$state" == "dimming" ]]
    else
        return 1
    fi
}

_get_dim_info() {
    local field="${1:-state}"
    local default="${2:-}"

    command -v jq &>/dev/null || { echo "$default"; return; }

    [[ ! -f "${RUNTIME_DIR}/dim-info.json" ]] && { echo "$default"; return; }

    jq -r ".${field} // \"${default}\"" \
        "${RUNTIME_DIR}/dim-info.json" 2>/dev/null || echo "$default"
}

_get_time_since_dim() {
    local dimmed_at
    dimmed_at="$(_get_dim_info 'dimmed_at' '')"
    [[ -z "$dimmed_at" ]] && echo "0" && return

    local dim_ts now_ts
    dim_ts="$(date -d "$dimmed_at" +%s 2>/dev/null || echo '0')"
    now_ts="$(date +%s)"
    echo "$(( now_ts - dim_ts ))"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BRIGHTNESS BACKEND (mirrors dim-screen.sh)
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_current_brightness() {
    local device="${1:-}"

    if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        local pct
        if [[ -n "$device" ]]; then
            pct="$(brightnessctl --device="$device" -m 2>/dev/null \
                | awk -F, '{gsub(/%/,"",$4); print int($4)}')"
        else
            pct="$(brightnessctl -m 2>/dev/null \
                | awk -F, '{gsub(/%/,"",$4); print int($4)}')"
        fi
        echo "${pct:-50}"
        return 0
    fi

    if [[ "$HAS_XRANDR" == "true" ]] && [[ "$IS_WAYLAND" == "false" ]]; then
        xrandr --verbose 2>/dev/null \
            | grep -i brightness \
            | head -1 \
            | awk '{printf "%d", $2*100}' || echo "50"
        return 0
    fi

    local sysfs_path="/sys/class/backlight"
    local dev_path
    dev_path="$(ls "$sysfs_path" 2>/dev/null | head -1 || echo '')"
    if [[ -n "$dev_path" ]]; then
        local cur max
        cur="$(cat "${sysfs_path}/${dev_path}/brightness"     2>/dev/null || echo 0)"
        max="$(cat "${sysfs_path}/${dev_path}/max_brightness" 2>/dev/null || echo 100)"
        echo "$(( cur * 100 / max ))"
    else
        echo "50"
    fi
}

_set_brightness_instant() {
    local target="$1"
    local device="${2:-}"

    (( target < 0 ))   && target=0
    (( target > 100 )) && target=100

    if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
        if [[ -n "$device" ]]; then
            brightnessctl --device="$device" set "${target}%" -q 2>/dev/null \
                || true
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

    local sysfs_path="/sys/class/backlight"
    local dev_path
    dev_path="$(ls "$sysfs_path" 2>/dev/null | head -1 || echo '')"
    if [[ -n "$dev_path" ]]; then
        local max raw
        max="$(cat "${sysfs_path}/${dev_path}/max_brightness" 2>/dev/null \
            || echo 100)"
        raw=$(( target * max / 100 ))
        echo "$raw" > "${sysfs_path}/${dev_path}/brightness" 2>/dev/null \
            || true
    fi
}

_ddcutil_set_brightness() {
    local target="$1"
    local bus="${2:-}"

    [[ "$HAS_DDCUTIL" == "false" ]] && return 0
    (( target < 0 ))   && target=0
    (( target > 100 )) && target=100

    if [[ -n "$bus" ]]; then
        ddcutil setvcp 10 "$target" --bus "$bus" &>/dev/null || true
    else
        ddcutil setvcp 10 "$target" &>/dev/null || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MONITOR UTILITIES
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_monitors() {
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        hyprctl monitors -j 2>/dev/null || echo '[]'
        return 0
    fi
    [[ -f "$DIM_MONITOR_CACHE" ]] && cat "$DIM_MONITOR_CACHE" || echo '[]'
}

_is_monitor_excluded() {
    local name="$1"
    [[ -z "$CFG_EXCLUDE_MONITORS" ]] && return 1
    local IFS=','
    for ex in $CFG_EXCLUDE_MONITORS; do
        ex="$(echo "$ex" | xargs)"
        [[ "$name" == "$ex" ]] && return 0
    done
    return 1
}

_get_monitor_backlight_device() {
    local monitor_name="$1"
    case "$monitor_name" in
        eDP-*|LVDS-*|DSI-*)
            if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
                brightnessctl --list 2>/dev/null \
                    | grep -oP "'\K[^']+" \
                    | grep -iE 'intel_backlight|amdgpu_bl|backlight' \
                    | head -1 || echo ""
            fi
            ;;
        HDMI-*|DP-*|DisplayPort-*)
            echo "external:$monitor_name"
            ;;
        *)
            echo ""
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# EASING ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ease() {
    local progress="$1"
    local easing="${2:-ease-out}"

    if [[ "$HAS_PYTHON" == "true" ]]; then
        python3 -c "
import math
p = float('$progress')
easing = '$easing'

def ease_out_cubic(t):
    return 1 - pow(1 - t, 3)

def ease_out_expo(t):
    if t == 1: return 1
    return 1 - pow(2, -10 * t)

def ease_out_back(t):
    c1 = 1.70158
    c3 = c1 + 1
    return 1 + c3 * pow(t - 1, 3) + c1 * pow(t - 1, 2)

def ease_in_out_cubic(t):
    if t < 0.5:
        return 4 * t * t * t
    return 1 - pow(-2 * t + 2, 3) / 2

def ease_out_elastic(t):
    c4 = (2 * math.pi) / 3
    if t == 0: return 0
    if t == 1: return 1
    return pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1

def linear(t):
    return t

funcs = {
    'ease-out':         ease_out_cubic,
    'ease-out-cubic':   ease_out_cubic,
    'ease-out-expo':    ease_out_expo,
    'ease-out-back':    ease_out_back,
    'ease-in-out':      ease_in_out_cubic,
    'ease-out-elastic': ease_out_elastic,
    'linear':           linear,
}

fn = funcs.get(easing, ease_out_cubic)
result = max(0.0, min(1.0, fn(p)))
print(f'{result:.6f}')
"
    else
        echo "$progress"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SMOOTH ANIMATION ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_stop_dim_animation() {
    if [[ -f "$DIM_ANIM_PID_FILE" ]]; then
        local pid
        pid="$(cat "$DIM_ANIM_PID_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            log_debug "Interrupted dim animation (PID=$pid)"
        fi
        rm -f "$DIM_ANIM_PID_FILE"
    fi
}

_animate_brightness_restore() {
    local from_pct="$1"
    local to_pct="$2"
    local duration_ms="$3"
    local steps="$4"
    local easing="${5:-ease-out}"
    local device="${6:-}"
    local is_external="${7:-false}"

    local step_time_us
    step_time_us="$(( duration_ms * 1000 / steps ))"

    local range
    range=$(( to_pct - from_pct ))

    log_debug "Restore animate: ${from_pct}% → ${to_pct}% \
over ${duration_ms}ms in ${steps} steps easing=${easing}"

    for (( i=1; i<=steps; i++ )); do
        local progress
        progress="$(awk "BEGIN {printf \"%.6f\", $i/$steps}")"

        local eased
        eased="$(_ease "$progress" "$easing")"

        local current_pct
        current_pct="$(awk \
            "BEGIN {printf \"%d\", $from_pct + ($range * $eased)}")"

        (( current_pct < 0 ))   && current_pct=0
        (( current_pct > 100 )) && current_pct=100

        if [[ "$is_external" == "true" ]]; then
            _ddcutil_set_brightness "$current_pct" "$device" 2>/dev/null \
                || true
        else
            _set_brightness_instant "$current_pct" "$device"
        fi

        if command -v usleep &>/dev/null; then
            usleep "$step_time_us" 2>/dev/null || sleep 0
        else
            sleep 0 2>/dev/null || true
        fi
    done

    # Ensure exact final value
    if [[ "$is_external" == "true" ]]; then
        _ddcutil_set_brightness "$to_pct" "$device" 2>/dev/null || true
    else
        _set_brightness_instant "$to_pct" "$device"
    fi

    log_debug "Restore animation complete: ${to_pct}%"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAKEUP BRIGHTNESS BOOST
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_apply_wakeup_boost() {
    local target_brightness="$1"
    local device="${2:-}"
    local is_external="${3:-false}"

    [[ "$CFG_WAKEUP_BRIGHTNESS_BOOST" != "true" ]] && return 0
    [[ "$target_brightness" -le 0 ]] && return 0

    local boost_target
    boost_target=$(( target_brightness + CFG_BOOST_AMOUNT ))
    (( boost_target > DEFAULT_MAX_BRIGHTNESS )) && \
        boost_target=$DEFAULT_MAX_BRIGHTNESS

    # Quick burst to boost level then settle
    log_debug "Wakeup boost: ${target_brightness}% → ${boost_target}% → ${target_brightness}%"

    local boost_steps=$(( CFG_BOOST_DURATION / 20 ))
    (( boost_steps < 3 )) && boost_steps=3

    # Rise to boost
    _animate_brightness_restore \
        "$target_brightness" \
        "$boost_target" \
        "$(( CFG_BOOST_DURATION / 2 ))" \
        "$boost_steps" \
        "ease-out" \
        "$device" \
        "$is_external"

    sleep "0.0$(printf '%03d' "$(( CFG_BOOST_DURATION / 4 ))")" 2>/dev/null \
        || true

    # Settle back to target
    _animate_brightness_restore \
        "$boost_target" \
        "$target_brightness" \
        "$(( CFG_BOOST_DURATION / 2 ))" \
        "$boost_steps" \
        "ease-in-out" \
        "$device" \
        "$is_external"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GAMMA RESTORE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_restore_gamma() {
    log_debug "Restoring gamma…"

    # Kill dim-related gammastep/wlsunset instances
    pkill -x gammastep &>/dev/null || true
    pkill -x wlsunset  &>/dev/null || true
    sleep 0.15

    # Restore night light if it was active before dim
    if [[ "$CFG_RESTORE_NIGHT_LIGHT" == "true" ]]; then
        if [[ -f "$DIM_BRIGHTNESS_BACKUP" ]] && \
           command -v jq &>/dev/null; then
            local nl_was_active
            nl_was_active="$(jq -r '.night_light_active // false' \
                "$DIM_BRIGHTNESS_BACKUP" 2>/dev/null)"

            if [[ "$nl_was_active" == "true" ]]; then
                log_debug "Restoring night light…"

                # Re-apply night light via script
                local nl_script="${SCRIPT_DIR}/../../swaync/scripts/night-light-on.sh"
                if [[ -x "$nl_script" ]]; then
                    "$nl_script" --silent &>/dev/null & true
                    log_debug "Night light restored via script"
                elif command -v gammastep &>/dev/null; then
                    # Read saved colortemp
                    local ct
                    ct="$(cat "${CACHE_DIR}/night-light-temp" 2>/dev/null \
                        || echo '3500')"
                    gammastep -O "$ct" &>/dev/null &
                    disown 2>/dev/null || true
                    log_debug "Night light restored: ${ct}K"
                elif command -v wlsunset &>/dev/null; then
                    local ct
                    ct="$(cat "${CACHE_DIR}/night-light-temp" 2>/dev/null \
                        || echo '3500')"
                    wlsunset -T "$ct" -t "$ct" &>/dev/null &
                    disown 2>/dev/null || true
                fi
                return 0
            fi
        fi
    fi

    # Plain gamma reset (no night light)
    if [[ "$HAS_XRANDR" == "true" ]]; then
        while IFS= read -r output; do
            xrandr --output "$output" --gamma "1:1:1" &>/dev/null || true
        done < <(xrandr 2>/dev/null | grep ' connected' | awk '{print $1}')
        log_debug "xrandr gamma reset"
    fi

    log_debug "Gamma restore complete"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HYPRLAND RESTORE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_restore_hyprland() {
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    # Restore opacity
    hyprctl keyword decoration:active_opacity   "1.0" &>/dev/null || true
    hyprctl keyword decoration:inactive_opacity "1.0" &>/dev/null || true

    log_debug "Hyprland opacity restored"
}

_restore_dpms() {
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    local monitors
    monitors="$(hyprctl monitors -j 2>/dev/null || echo '[]')"

    echo "$monitors" | command -v jq &>/dev/null && \
        jq -r '.[].name' 2>/dev/null | \
    while IFS= read -r mon; do
        hyprctl dispatch dpms on "$mon" &>/dev/null || true
    done

    log_debug "DPMS restored on all monitors"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAYBAR / SWAYNC INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_waybar() {
    pkill -SIGRTMIN+4 waybar 2>/dev/null || true
    log_debug "Waybar signaled SIGRTMIN+4"
}

_update_swaync_widget() {
    local state="$1"
    local level="${2:-}"

    jq -n \
        --arg state "$state" \
        --arg level "$level" \
        --arg ts    "$(date -Iseconds)" \
        '{"state":$state,"level":$level,"updated":$ts}' \
        > "${RUNTIME_DIR}/dim-status.json" 2>/dev/null || true
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
    notify-send \
        --urgency=low \
        --expire-time=2000 \
        --app-name="ASH Idle" \
        "${1:-}" "${2:-}" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANALYTICS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_record_undim_event() {
    local restored_to="${1:-0}"
    local dim_duration_secs="${2:-0}"

    command -v jq &>/dev/null || return 0

    [[ ! -f "$UNDIM_HISTORY_FILE" ]] && \
        echo '{"events":[],"total_undims":0}' > "$UNDIM_HISTORY_FILE"

    jq \
        --argjson to   "$restored_to" \
        --argjson secs "$dim_duration_secs" \
        --arg ts       "$(date -Iseconds)" \
        '.events += [{
            "restored_to_pct": $to,
            "dim_duration_secs": $secs,
            "timestamp": $ts
        }] |
        .events = .events[-200:] |
        .total_undims += 1' \
        "$UNDIM_HISTORY_FILE" \
        > "${UNDIM_HISTORY_FILE}.tmp" 2>/dev/null && \
    mv "${UNDIM_HISTORY_FILE}.tmp" "$UNDIM_HISTORY_FILE"

    # Also record in dim history
    if [[ -f "$DIM_HISTORY_FILE" ]] && command -v jq &>/dev/null; then
        jq \
            --argjson to "$restored_to" \
            --arg ts "$(date -Iseconds)" \
            '.events += [{
                "event":     "undim",
                "level":     $to,
                "timestamp": $ts
            }] | .events = .events[-200:]' \
            "$DIM_HISTORY_FILE" \
            > "${DIM_HISTORY_FILE}.tmp" 2>/dev/null && \
        mv "${DIM_HISTORY_FILE}.tmp" "$DIM_HISTORY_FILE"
    fi

    log_debug "Undim history recorded: to=${restored_to}% dim_time=${dim_duration_secs}s"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE UNDIM OPERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_do_undim() {
    local target_brightness="${1:-}"  # Optional override
    local duration_ms="${2:-}"
    local steps="${3:-}"
    local easing="${4:-}"
    local force="${5:-false}"

    [[ -z "$duration_ms" ]] && duration_ms="$CFG_UNDIM_DURATION"
    [[ -z "$steps"       ]] && steps="$CFG_UNDIM_STEPS"
    [[ -z "$easing"      ]] && easing="$CFG_UNDIM_EASING"

    # Check if actually dimmed (unless forced)
    if [[ "$force" == "false" ]] && ! _is_currently_dimmed; then
        log_info "Screen is not dimmed — nothing to restore"
        # Still reset Hyprland just in case
        _restore_hyprland
        return 0
    fi

    # Calculate time spent dimmed (for analytics)
    local dim_duration_secs=0
    dim_duration_secs="$(_get_time_since_dim)"

    log_info "Undimming: duration=${duration_ms}ms steps=${steps} \
easing=${easing} (was dimmed for ${dim_duration_secs}s)"

    # Stop any active dim animation
    _stop_dim_animation

    # Mark as restoring
    echo "restoring" > "$DIM_STATE_FILE"

    # ── Restore DPMS first if it was off ─────────────────────────────────
    _restore_dpms

    # ── Restore Hyprland opacity immediately ─────────────────────────────
    _restore_hyprland

    # ── Get monitors ─────────────────────────────────────────────────────
    local monitors
    monitors="$(_get_monitors)"
    local monitor_names=()

    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        while IFS= read -r name; do
            [[ -n "$name" ]] && monitor_names+=("$name")
        done < <(echo "$monitors" | jq -r '.[].name' 2>/dev/null)
    fi

    [[ ${#monitor_names[@]} -eq 0 ]] && monitor_names+=("primary")

    # ── Restore each monitor ─────────────────────────────────────────────
    local first_monitor=true
    local restored_to=0

    for mon in "${monitor_names[@]}"; do
        if _is_monitor_excluded "$mon"; then
            log_debug "Skip restore: excluded monitor $mon"
            continue
        fi

        local backlight_dev
        backlight_dev="$(_get_monitor_backlight_device "$mon")"

        local restore_target
        local is_external=false

        # Determine restore target
        if [[ -n "$target_brightness" ]]; then
            restore_target="$target_brightness"
        elif [[ "$CFG_RESTORE_EXACT" == "true" ]] && \
             [[ -f "$DIM_BRIGHTNESS_BACKUP" ]]; then
            if command -v jq &>/dev/null; then
                restore_target="$(jq -r \
                    --arg mon "$mon" \
                    '.monitors[$mon].brightness // 0' \
                    "$DIM_BRIGHTNESS_BACKUP" 2>/dev/null || echo '0')"

                # Try primary if monitor-specific not found
                if [[ "$restore_target" == "0" || -z "$restore_target" ]]; then
                    restore_target="$(jq -r \
                        '[.monitors[] | .brightness] | first // 0' \
                        "$DIM_BRIGHTNESS_BACKUP" 2>/dev/null || echo '0')"
                fi
            else
                restore_target="$DEFAULT_FALLBACK_BRIGHTNESS"
            fi
        else
            restore_target="$DEFAULT_FALLBACK_BRIGHTNESS"
        fi

        # Fallback if still 0
        if [[ -z "$restore_target" ]] || (( restore_target <= 0 )); then
            restore_target="$DEFAULT_FALLBACK_BRIGHTNESS"
            log_warn "No saved state for $mon — using fallback: ${restore_target}%"
        fi

        # Cap at 100%
        (( restore_target > DEFAULT_MAX_BRIGHTNESS )) && \
            restore_target=$DEFAULT_MAX_BRIGHTNESS

        # Get device path from backup if available
        if [[ -f "$DIM_BRIGHTNESS_BACKUP" ]] && command -v jq &>/dev/null; then
            local saved_dev
            saved_dev="$(jq -r \
                --arg mon "$mon" \
                '.monitors[$mon].device // ""' \
                "$DIM_BRIGHTNESS_BACKUP" 2>/dev/null || echo '')"

            [[ -n "$saved_dev" ]] && backlight_dev="$saved_dev"
        fi

        if [[ "$backlight_dev" == external:* ]]; then
            is_external=true
            local bus="${backlight_dev#external:}"
            log_debug "Restoring external monitor $mon → ${restore_target}%"
        fi

        local current_brightness
        if [[ "$is_external" == "true" ]]; then
            current_brightness="$(ddcutil getvcp 10 2>/dev/null \
                | grep 'current value' | awk '{print $NF}' || echo '0')"
        else
            current_brightness="$(_get_current_brightness "$backlight_dev")"
        fi

        log_debug "Restoring $mon: ${current_brightness}% → ${restore_target}% \
device='$backlight_dev' external=$is_external"

        if [[ "$first_monitor" == "true" ]]; then
            _animate_brightness_restore \
                "$current_brightness" \
                "$restore_target" \
                "$duration_ms" \
                "$steps" \
                "$easing" \
                "$backlight_dev" \
                "$is_external"

            # Apply wakeup boost after reaching target
            _apply_wakeup_boost \
                "$restore_target" \
                "$backlight_dev" \
                "$is_external"

            first_monitor=false
            restored_to="$restore_target"
        else
            (
                _animate_brightness_restore \
                    "$current_brightness" \
                    "$restore_target" \
                    "$duration_ms" \
                    "$steps" \
                    "$easing" \
                    "$backlight_dev" \
                    "$is_external"
            ) &
        fi
    done

    # Wait for parallel animations
    wait 2>/dev/null || true

    # ── Restore gamma ─────────────────────────────────────────────────────
    if [[ "$CFG_RESTORE_GAMMA" == "true" ]]; then
        _restore_gamma
    fi

    # ── Update state ─────────────────────────────────────────────────────
    echo "undimmed" > "$DIM_STATE_FILE"

    rm -f \
        "${RUNTIME_DIR}/dim-info.json" \
        "$DIM_BRIGHTNESS_BACKUP"

    jq -n \
        --argjson to  "$restored_to" \
        --argjson secs "$dim_duration_secs" \
        --arg ts "$(date -Iseconds)" \
        '{
            "state":               "undimmed",
            "restored_to_pct":     $to,
            "dim_duration_secs":   $secs,
            "restored_at":         $ts
        }' > "${RUNTIME_DIR}/undim-info.json" 2>/dev/null || true

    # Signal Waybar & SwayNC
    _signal_waybar
    _update_swaync_widget "undimmed" "${restored_to}%"

    # Analytics
    _record_undim_event "$restored_to" "$dim_duration_secs"

    # Sound / notify
    _play_sound "$SOUND_UNDIM"
    _show_notification "${ICON_SUN}  Screen Restored" \
        "Brightness: ${restored_to}%"

    # Run hook
    local hook="${CONFIG_DIR}/hooks/post-undim.sh"
    [[ -f "$hook" && -x "$hook" ]] && \
        DIM_RESTORED_TO="$restored_to" \
        DIM_WAS_SECONDS="$dim_duration_secs" \
        "$hook" & true

    log_success "Screen restored to ${restored_to}%"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH Undim Screen v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [OPTIONS]

${CLR_BOLD}OPTIONS${CLR_RESET}
  ${CLR_GREEN}--level N${CLR_RESET}          Override restore brightness % (default: saved)
  ${CLR_GREEN}--duration MS${CLR_RESET}      Restore transition ms (default: ${DEFAULT_UNDIM_DURATION})
  ${CLR_GREEN}--steps N${CLR_RESET}          Animation steps (default: ${DEFAULT_UNDIM_STEPS})
  ${CLR_GREEN}--easing NAME${CLR_RESET}      Easing function (ease-out|linear|ease-in-out)
  ${CLR_YELLOW}--no-gamma${CLR_RESET}         Skip gamma restore
  ${CLR_YELLOW}--no-night-light${CLR_RESET}   Skip night light restore
  ${CLR_YELLOW}--no-boost${CLR_RESET}         Skip wakeup brightness boost
  ${CLR_BLUE}--monitor NAME${CLR_RESET}    Restore specific monitor only
  ${CLR_CYAN}--instant${CLR_RESET}          No animation (instant restore)
  ${CLR_CYAN}--force${CLR_RESET}            Restore even if not flagged as dimmed
  ${CLR_WHITE}--status${CLR_RESET}           Show undim/dim status
  ${CLR_WHITE}--history${CLR_RESET}          Show undim history
  ${CLR_WHITE}--version${CLR_RESET}          Show version
  ${CLR_WHITE}--help${CLR_RESET}             Show help

${CLR_BOLD}EASING FUNCTIONS${CLR_RESET}
  ease-out         (default) — fast start, smooth landing
  ease-out-expo    — exponential deceleration
  ease-out-back    — slight overshoot + settle
  ease-out-elastic — elastic bounce to target
  ease-in-out      — symmetric smooth
  linear           — constant speed

${CLR_BOLD}EXAMPLES${CLR_RESET}
  $(basename "$0")                            # Standard restore
  $(basename "$0") --instant                  # No animation
  $(basename "$0") --level 90                 # Restore to 90%
  $(basename "$0") --duration 500             # Very fast restore
  $(basename "$0") --force                    # Force restore
  $(basename "$0") --easing ease-out-back     # Bouncy restore

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    _ensure_dirs
    _detect_capabilities
    _load_profile
    _acquire_lock || {
        log_error "Lock failed — another undim in progress"
        exit 0
    }

    local target_brightness=""
    local duration_ms=""
    local steps=""
    local easing=""
    local force=false
    local instant=false
    local no_gamma=false
    local no_night_light=false
    local no_boost=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --level|-l)
                shift; target_brightness="${1:-}"
                ;;
            --level=*)
                target_brightness="${1#--level=}"
                ;;
            --duration|-d)
                shift; duration_ms="${1:-}"
                ;;
            --steps|-s)
                shift; steps="${1:-}"
                ;;
            --easing|-e)
                shift; easing="${1:-}"
                ;;
            --no-gamma)
                no_gamma=true
                CFG_RESTORE_GAMMA=false
                ;;
            --no-night-light)
                no_night_light=true
                CFG_RESTORE_NIGHT_LIGHT=false
                ;;
            --no-boost)
                no_boost=true
                CFG_WAKEUP_BRIGHTNESS_BOOST=false
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
                local dim_state="undimmed"
                [[ -f "$DIM_STATE_FILE" ]] && \
                    dim_state="$(cat "$DIM_STATE_FILE" 2>/dev/null)"

                jq -n \
                    --arg state "$dim_state" \
                    --arg updated "$(date -Iseconds)" \
                    '{"state":$state,"updated":$updated}'
                exit 0
                ;;
            --history)
                if [[ -f "$UNDIM_HISTORY_FILE" ]]; then
                    jq '.events[-10:] | reverse' \
                        "$UNDIM_HISTORY_FILE" 2>/dev/null
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
                if [[ "$1" =~ ^[0-9]+$ ]]; then
                    target_brightness="$1"
                else
                    log_warn "Unknown argument: $1"
                fi
                ;;
        esac
        shift 2>/dev/null || break
    done

    _do_undim \
        "$target_brightness" \
        "$duration_ms" \
        "$steps" \
        "$easing" \
        "$force"

    exit 0
}

main "$@"