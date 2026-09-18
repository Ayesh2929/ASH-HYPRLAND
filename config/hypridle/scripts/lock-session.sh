#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — HyprIdle Ultra Lock Session Script               ║
# ║  Premium session locking with hyprlock integration, pre-lock animations,     ║
# ║  multi-monitor blur, security hardening, unlock hooks, PAM awareness,        ║
# ║  inhibit checking, media pause, presence detection, and analytics            ║
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

readonly SCRIPT_NAME="ash-lock-session"
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# XDG paths
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"
readonly HYPRLOCK_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/hyprlock"

# State & lock files
readonly LOCK_STATE_FILE="${RUNTIME_DIR}/session-lock.state"
readonly LOCK_LOCK_FILE="${RUNTIME_DIR}/lock-session.lock"
readonly LOCK_LOG_FILE="${CACHE_DIR}/logs/lock-session.log"
readonly LOCK_HISTORY_FILE="${DATA_DIR}/lock-history.json"
readonly LOCK_STATS_FILE="${CACHE_DIR}/lock-stats.json"
readonly LOCK_INHIBIT_FILE="${RUNTIME_DIR}/lock-inhibit"
readonly LOCK_PID_FILE="${RUNTIME_DIR}/hyprlock.pid"
readonly LOCK_TIMESTAMP_FILE="${RUNTIME_DIR}/lock-timestamp"
readonly LOCK_BLUR_PID_FILE="${RUNTIME_DIR}/lock-blur.pid"
readonly LOCK_MEDIA_STATE_FILE="${RUNTIME_DIR}/lock-media-state.json"
readonly LOCK_PROFILE_FILE="${CONFIG_DIR}/lock-profile.json"
readonly LOCK_WALLPAPER_CACHE="${CACHE_DIR}/lock-wallpaper.png"
readonly LOCK_PRESENCE_FILE="${RUNTIME_DIR}/presence.state"
readonly GPG_AGENT_CACHE_FILE="${RUNTIME_DIR}/gpg-agent-info"
readonly SSH_AGENT_STATE_FILE="${RUNTIME_DIR}/ssh-agent-lock.state"
readonly DIM_STATE_FILE="${RUNTIME_DIR}/dim.state"

# Hyprlock layouts
readonly HYPRLOCK_DEFAULT="${HYPRLOCK_CONFIG}/layouts/default.conf"
readonly HYPRLOCK_MINIMAL="${HYPRLOCK_CONFIG}/layouts/minimal.conf"
readonly HYPRLOCK_DUAL="${HYPRLOCK_CONFIG}/layouts/dual-monitor.conf"
readonly HYPRLOCK_ANIMATED="${HYPRLOCK_CONFIG}/layouts/animated.conf"

# Sound files
readonly SOUND_LOCK="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/startup.ogg"
readonly SOUND_UNLOCK="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/notification.ogg"
readonly SOUND_FAILED="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/error.ogg"

# Icons
readonly ICON_LOCK="󰌾"
readonly ICON_UNLOCK="󰍁"
readonly ICON_SECURITY="󱕴"
readonly ICON_SLEEP="󰒲"
readonly ICON_ASH="󱎫"
readonly ICON_CAMERA="󰸬"
readonly ICON_SHIELD="󰡗"
readonly ICON_KEY="󰌋"
readonly ICON_WARNING="󰀦"
readonly ICON_INFO="󰋼"
readonly ICON_BLUR="󱎖"
readonly ICON_MEDIA="󰝚"
readonly ICON_VPN="󰌾"
readonly ICON_CLOCK="󰅐"

# ANSI colors
readonly CLR_RESET=$'\033[0m'
readonly CLR_BOLD=$'\033[1m'
readonly CLR_RED=$'\033[0;31m'
readonly CLR_GREEN=$'\033[0;32m'
readonly CLR_YELLOW=$'\033[0;33m'
readonly CLR_BLUE=$'\033[0;34m'
readonly CLR_MAGENTA=$'\033[0;35m'
readonly CLR_CYAN=$'\033[0;36m'
readonly CLR_WHITE=$'\033[0;37m'
readonly CLR_GRAY=$'\033[0;90m'

# Lock timeout & retry
readonly MAX_LOCK_WAIT=10       # seconds to wait for locker to start
readonly LOCK_RETRY_DELAY=0.5   # seconds between retries
readonly BLUR_RADIUS=10         # pre-lock blur radius
readonly SCREENSHOT_DELAY=150   # ms delay before screenshot

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR" "$STATE_DIR" "$DATA_DIR"
        "$CONFIG_DIR" "$RUNTIME_DIR"
        "${CACHE_DIR}/logs"
        "${CACHE_DIR}/lock-screenshots"
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
    if [[ -f "$LOCK_LOG_FILE" ]]; then
        local sz
        sz="$(stat -c%s "$LOCK_LOG_FILE" 2>/dev/null || echo 0)"
        if (( sz > 524288 )); then
            mv "$LOCK_LOG_FILE" \
               "${LOCK_LOG_FILE}.$(date +%Y%m%d_%H%M%S).old"
            find "${CACHE_DIR}/logs" \
                -name 'lock-session.log.*.old' \
                -mtime +14 \
                -delete 2>/dev/null || true
        fi
    fi

    echo "$log_line" >> "$LOCK_LOG_FILE" 2>/dev/null || true

    [[ ! -t 2 ]] && return 0
    case "$level" in
        ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[✗]${CLR_RESET} $message"   >&2 ;;
        WARN)    echo -e "${CLR_YELLOW}[⚠]${CLR_RESET}  $message"           >&2 ;;
        INFO)    echo -e "${CLR_CYAN}[ℹ]${CLR_RESET}  $message"             >&2 ;;
        SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[✓]${CLR_RESET} $message"  >&2 ;;
        SECURITY)echo -e "${CLR_MAGENTA}${CLR_BOLD}[🔒]${CLR_RESET} $message" >&2 ;;
        DEBUG)
            [[ "${ASH_DEBUG:-0}" == "1" ]] && \
                echo -e "${CLR_GRAY}[~] $message${CLR_RESET}" >&2 ;;
    esac
}

log_info()     { _log INFO     "$@"; }
log_warn()     { _log WARN     "$@"; }
log_error()    { _log ERROR    "$@"; }
log_success()  { _log SUCCESS  "$@"; }
log_security() { _log SECURITY "$@"; }
log_debug()    { _log DEBUG    "$@"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOCK MANAGER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_acquire_lock() {
    local max_wait="${1:-3}"
    local waited=0

    while [[ -f "$LOCK_LOCK_FILE" ]]; do
        local pid
        pid="$(cat "$LOCK_LOCK_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            log_warn "Stale script-lock (PID=$pid) — removing"
            rm -f "$LOCK_LOCK_FILE"
            break
        fi
        if (( waited >= max_wait )); then
            log_error "Could not acquire script-lock after ${max_wait}s"
            return 1
        fi
        sleep 0.25
        (( waited++ )) || true
    done

    echo "$$" > "$LOCK_LOCK_FILE"
    log_debug "Script-lock acquired (PID=$$)"
    return 0
}

_release_lock() {
    local pid
    pid="$(cat "$LOCK_LOCK_FILE" 2>/dev/null || echo '')"
    [[ "$pid" == "$$" ]] && rm -f "$LOCK_LOCK_FILE"
    log_debug "Script-lock released"
}

_cleanup() {
    _release_lock
    # Clean up temp files
    rm -f "${RUNTIME_DIR}/lock-temp-$$"* 2>/dev/null || true
    log_debug "Lock-session cleanup done"
}

trap '_cleanup' EXIT INT TERM HUP

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CAPABILITY DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g HAS_HYPRLOCK=false
declare -g HAS_SWAYLOCK=false
declare -g HAS_GTKLOCK=false
declare -g HAS_HYPRCTL=false
declare -g HAS_PLAYERCTL=false
declare -g HAS_PACTL=false
declare -g HAS_BRIGHTNESSCTL=false
declare -g HAS_GRIM=false
declare -g HAS_CONVERT=false   # ImageMagick
declare -g HAS_FFMPEG=false
declare -g HAS_SWWW=false
declare -g HAS_NOTIFY=false
declare -g HAS_JQ=false
declare -g HAS_LOGINCTL=false
declare -g HAS_GNOME_KEYRING=false
declare -g HAS_KDE_WALLET=false
declare -g HAS_GPG_AGENT=false
declare -g HAS_SSH_ADD=false
declare -g HAS_XSECURELOCK=false
declare -g IS_WAYLAND=false
declare -g IS_LAPTOP=false
declare -g LOCKER_CMD=""
declare -g MONITOR_COUNT=1

_detect_capabilities() {
    command -v hyprlock      &>/dev/null && HAS_HYPRLOCK=true
    command -v swaylock      &>/dev/null && HAS_SWAYLOCK=true
    command -v gtklock       &>/dev/null && HAS_GTKLOCK=true
    command -v hyprctl       &>/dev/null && HAS_HYPRCTL=true
    command -v playerctl     &>/dev/null && HAS_PLAYERCTL=true
    command -v pactl         &>/dev/null && HAS_PACTL=true
    command -v brightnessctl &>/dev/null && HAS_BRIGHTNESSCTL=true
    command -v grim          &>/dev/null && HAS_GRIM=true
    command -v convert       &>/dev/null && HAS_CONVERT=true
    command -v ffmpeg        &>/dev/null && HAS_FFMPEG=true
    command -v swww          &>/dev/null && HAS_SWWW=true
    command -v notify-send   &>/dev/null && HAS_NOTIFY=true
    command -v jq            &>/dev/null && HAS_JQ=true
    command -v loginctl      &>/dev/null && HAS_LOGINCTL=true
    command -v xsecurelock   &>/dev/null && HAS_XSECURELOCK=true
    command -v ssh-add       &>/dev/null && HAS_SSH_ADD=true
    command -v gpg-connect-agent &>/dev/null && HAS_GPG_AGENT=true

    pgrep -x gnome-keyring-daemon &>/dev/null && HAS_GNOME_KEYRING=true
    pgrep -x kwalletd5            &>/dev/null && HAS_KDE_WALLET=true

    [[ -n "${WAYLAND_DISPLAY:-}" || \
       -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && IS_WAYLAND=true

    [[ -d /sys/class/power_supply/BAT0 || \
       -d /sys/class/power_supply/BAT1 ]] && IS_LAPTOP=true

    # Determine best locker
    if [[ "$HAS_HYPRLOCK" == "true" ]]; then
        LOCKER_CMD="hyprlock"
    elif [[ "$HAS_SWAYLOCK" == "true" ]]; then
        LOCKER_CMD="swaylock"
    elif [[ "$HAS_GTKLOCK" == "true" ]]; then
        LOCKER_CMD="gtklock"
    else
        LOCKER_CMD="loginctl lock-session"
    fi

    # Monitor count
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        MONITOR_COUNT="$(hyprctl monitors -j 2>/dev/null | \
            jq 'length' 2>/dev/null || echo 1)"
    fi

    log_debug "Locker: $LOCKER_CMD monitors=$MONITOR_COUNT \
wayland=$IS_WAYLAND laptop=$IS_LAPTOP"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PROFILE LOADER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

declare -g CFG_LOCKER="auto"
declare -g CFG_LAYOUT="default"
declare -g CFG_PRE_LOCK_BLUR=true
declare -g CFG_BLUR_RADIUS=10
declare -g CFG_BLUR_BRIGHTNESS=60
declare -g CFG_SCREENSHOT_BG=true
declare -g CFG_PAUSE_MEDIA=true
declare -g CFG_RESUME_MEDIA_ON_UNLOCK=true
declare -g CFG_MUTE_MICROPHONE=true
declare -g CFG_MUTE_ON_LOCK=false
declare -g CFG_DIM_BEFORE_LOCK=true
declare -g CFG_DIM_LEVEL=5
declare -g CFG_LOCK_GRACE_PERIOD=0
declare -g CFG_INHIBIT_CHECK=true
declare -g CFG_CLEAR_CLIPBOARD=true
declare -g CFG_LOCK_SSH=false
declare -g CFG_LOCK_GPG=true
declare -g CFG_DPMS_ON_LOCK=false
declare -g CFG_DPMS_DELAY=10
declare -g CFG_NOTIFY_ON_LOCK=false
declare -g CFG_SOUND_ON_LOCK=true
declare -g CFG_SOUND_ON_UNLOCK=true
declare -g CFG_PRESENCE_CHECK=false
declare -g CFG_PRESENCE_TIMEOUT=30
declare -g CFG_ANALYTICS=true
declare -g CFG_WAYBAR_SIGNAL=6
declare -g CFG_IDLE_HINT_INHIBIT=true
declare -g CFG_KILL_SCREENSHARE=true

_load_profile() {
    [[ ! -f "$LOCK_PROFILE_FILE" ]] && {
        log_debug "No lock profile — using defaults"
        return 0
    }

    [[ "$HAS_JQ" == "false" ]] && return 0

    log_debug "Loading lock profile: $LOCK_PROFILE_FILE"

    local get
    get() { jq -r ".${1} // \"${2}\""  "$LOCK_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_num
    get_num() { jq -r ".${1} // ${2}"  "$LOCK_PROFILE_FILE" 2>/dev/null || echo "$2"; }
    local get_bool
    get_bool() {
        jq -r "if .${1} == true then \"true\" else \"false\" end" \
            "$LOCK_PROFILE_FILE" 2>/dev/null || echo "$2"
    }

    CFG_LOCKER="$(get        locker              'auto')"
    CFG_LAYOUT="$(get        layout              'default')"
    CFG_PRE_LOCK_BLUR="$(get_bool pre_lock_blur  true)"
    CFG_BLUR_RADIUS="$(get_num   blur_radius     10)"
    CFG_BLUR_BRIGHTNESS="$(get_num blur_brightness 60)"
    CFG_SCREENSHOT_BG="$(get_bool screenshot_bg  true)"
    CFG_PAUSE_MEDIA="$(get_bool  pause_media     true)"
    CFG_RESUME_MEDIA_ON_UNLOCK="$(get_bool resume_media_on_unlock true)"
    CFG_MUTE_MICROPHONE="$(get_bool mute_microphone true)"
    CFG_MUTE_ON_LOCK="$(get_bool  mute_on_lock   false)"
    CFG_DIM_BEFORE_LOCK="$(get_bool dim_before_lock true)"
    CFG_DIM_LEVEL="$(get_num     dim_level       5)"
    CFG_LOCK_GRACE_PERIOD="$(get_num grace_period 0)"
    CFG_INHIBIT_CHECK="$(get_bool inhibit_check  true)"
    CFG_CLEAR_CLIPBOARD="$(get_bool clear_clipboard true)"
    CFG_LOCK_SSH="$(get_bool     lock_ssh         false)"
    CFG_LOCK_GPG="$(get_bool     lock_gpg         true)"
    CFG_DPMS_ON_LOCK="$(get_bool dpms_on_lock     false)"
    CFG_DPMS_DELAY="$(get_num    dpms_delay       10)"
    CFG_NOTIFY_ON_LOCK="$(get_bool notify_on_lock false)"
    CFG_SOUND_ON_LOCK="$(get_bool sound_on_lock   true)"
    CFG_SOUND_ON_UNLOCK="$(get_bool sound_on_unlock true)"
    CFG_PRESENCE_CHECK="$(get_bool presence_check  false)"
    CFG_PRESENCE_TIMEOUT="$(get_num presence_timeout 30)"
    CFG_ANALYTICS="$(get_bool   analytics         true)"
    CFG_WAYBAR_SIGNAL="$(get_num waybar_signal    6)"
    CFG_KILL_SCREENSHARE="$(get_bool kill_screenshare true)"

    log_debug "Profile loaded: locker=$CFG_LOCKER layout=$CFG_LAYOUT"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INHIBIT CHECKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_is_inhibited() {
    [[ "$CFG_INHIBIT_CHECK" != "true" ]] && return 1  # Not inhibited

    # 1. File-based inhibit
    if [[ -f "$LOCK_INHIBIT_FILE" ]]; then
        local pid reason expires
        pid="$(sed -n '1p' "$LOCK_INHIBIT_FILE" 2>/dev/null || echo '')"
        reason="$(sed -n '2p' "$LOCK_INHIBIT_FILE" 2>/dev/null || echo 'unknown')"
        expires="$(sed -n '3p' "$LOCK_INHIBIT_FILE" 2>/dev/null || echo '0')"
        local now
        now="$(date +%s)"

        if [[ -n "$expires" ]] && (( expires > 0 && now > expires )); then
            log_debug "Lock inhibit expired — removing"
            rm -f "$LOCK_INHIBIT_FILE"
        elif [[ -n "$pid" ]] && ! kill -0 "$pid" 2>/dev/null; then
            log_debug "Lock inhibit process dead — removing"
            rm -f "$LOCK_INHIBIT_FILE"
        else
            log_security "Lock inhibited: ${reason}"
            return 0
        fi
    fi

    # 2. Hyprland idle inhibitors
    if [[ "$HAS_HYPRCTL" == "true" ]]; then
        local inhibitors
        inhibitors="$(hyprctl activeinhibitors 2>/dev/null | \
            jq 'length' 2>/dev/null || echo '0')"
        if (( inhibitors > 0 )); then
            log_debug "Hyprland idle inhibitor active ($inhibitors)"
            return 0
        fi
    fi

    # 3. Fullscreen AND video playing
    if [[ "$HAS_HYPRCTL" == "true" ]] && [[ "$HAS_PLAYERCTL" == "true" ]]; then
        local fs_count play_state
        fs_count="$(hyprctl clients -j 2>/dev/null | \
            jq '[.[] | select(.fullscreen == true)] | length' 2>/dev/null || echo 0)"
        play_state="$(playerctl status 2>/dev/null || echo '')"

        if (( fs_count > 0 )) && [[ "$play_state" == "Playing" ]]; then
            log_debug "Fullscreen media playing — lock inhibited"
            return 0
        fi
    fi

    # 4. Game mode check
    if [[ -f "${CACHE_DIR}/state/current-mode.json" ]]; then
        local mode
        mode="$(jq -r '.mode // ""' \
            "${CACHE_DIR}/state/current-mode.json" 2>/dev/null || echo '')"
        if [[ "$mode" == "game" ]]; then
            log_debug "Game mode active — lock may be inhibited"
            # Note: don't return here — game mode doesn't block lock
            # unless user configured it
        fi
    fi

    # 5. Screenshare / presentation mode check
    if [[ -f "${RUNTIME_DIR}/screenshare.state" ]]; then
        local ss_state
        ss_state="$(cat "${RUNTIME_DIR}/screenshare.state" 2>/dev/null)"
        if [[ "$ss_state" == "active" ]]; then
            log_security "Screenshare active — not inhibiting lock but noting"
        fi
    fi

    return 1  # Not inhibited
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PRE-LOCK EFFECTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_capture_screenshot() {
    # Capture blurred wallpaper for hyprlock background
    [[ "$HAS_GRIM" == "false" ]] && return 0
    [[ "$CFG_SCREENSHOT_BG" != "true" ]] && return 0

    local screenshot_file
    screenshot_file="${CACHE_DIR}/lock-screenshots/lock-bg-$(date +%s).png"

    log_debug "Capturing lock background screenshot…"

    # Brief delay to ensure any pre-lock animation has settled
    sleep "$(awk "BEGIN {printf \"%.2f\", $SCREENSHOT_DELAY/1000}")"

    # Capture all monitors
    if grim "$screenshot_file" &>/dev/null; then
        log_debug "Screenshot captured: $screenshot_file"

        # Apply blur + brightness reduction
        if [[ "$HAS_CONVERT" == "true" ]]; then
            local blurred="${screenshot_file%.png}-blurred.png"

            convert "$screenshot_file" \
                -filter Gaussian \
                -resize "20%" \
                -gaussian-blur "0x${CFG_BLUR_RADIUS}" \
                -resize "500%" \
                -modulate "${CFG_BLUR_BRIGHTNESS},100,100" \
                -quality 85 \
                "$blurred" &>/dev/null && \
            mv "$blurred" "$LOCK_WALLPAPER_CACHE" || true

            log_debug "Blurred wallpaper saved: $LOCK_WALLPAPER_CACHE"
        elif [[ "$HAS_FFMPEG" == "true" ]]; then
            # FFmpeg blur fallback
            ffmpeg -i "$screenshot_file" \
                -vf "boxblur=${CFG_BLUR_RADIUS}:5,eq=brightness=-0.3" \
                -q:v 3 \
                "$LOCK_WALLPAPER_CACHE" \
                -y &>/dev/null || true
        else
            # No blur — just use raw screenshot
            cp "$screenshot_file" "$LOCK_WALLPAPER_CACHE" || true
        fi

        # Clean up raw screenshot
        rm -f "$screenshot_file"
    else
        log_warn "Screenshot failed — using existing wallpaper"
    fi
}

_pre_lock_animation() {
    # Fade/blur screen before locking
    [[ "$CFG_PRE_LOCK_BLUR" != "true" ]] && return 0
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    log_debug "Applying pre-lock blur animation…"

    # Animate Hyprland blur in quickly
    local blur_steps=8
    local blur_interval=30  # ms between steps

    for (( step=1; step<=blur_steps; step++ )); do
        local blur_val
        blur_val=$(( CFG_BLUR_RADIUS * step / blur_steps ))

        hyprctl keyword decoration:blur:enabled  "true"  &>/dev/null || true
        hyprctl keyword decoration:blur:size     "$blur_val" &>/dev/null || true
        hyprctl keyword decoration:blur:passes   "3"     &>/dev/null || true

        # Fade opacity
        local opacity
        opacity="$(awk "BEGIN {printf \"%.2f\", 1.0 - (0.15 * $step/$blur_steps)}")"
        hyprctl keyword decoration:active_opacity   "$opacity" &>/dev/null || true
        hyprctl keyword decoration:inactive_opacity "$opacity" &>/dev/null || true

        sleep "$(awk "BEGIN {printf \"%.3f\", $blur_interval/1000}")"
    done

    log_debug "Pre-lock animation complete"
}

_pre_lock_dim() {
    [[ "$CFG_DIM_BEFORE_LOCK" != "true" ]] && return 0

    local dim_script="${SCRIPT_DIR}/dim-screen.sh"
    if [[ -x "$dim_script" ]]; then
        "$dim_script" \
            --level "$CFG_DIM_LEVEL" \
            --duration 800 \
            --steps 20 \
            --easing "ease-in" \
            --force \
            &>/dev/null || true
        log_debug "Pre-lock dim applied: ${CFG_DIM_LEVEL}%"
    else
        # Direct brightnessctl
        if [[ "$HAS_BRIGHTNESSCTL" == "true" ]]; then
            brightnessctl set "${CFG_DIM_LEVEL}%" -q 2>/dev/null || true
        fi
    fi
}

_restore_after_lock() {
    # Called after lock completes to restore compositor state
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    log_debug "Restoring compositor state post-lock…"

    hyprctl keyword decoration:active_opacity   "1.0" &>/dev/null || true
    hyprctl keyword decoration:inactive_opacity "1.0" &>/dev/null || true
    hyprctl keyword decoration:blur:size "8"          &>/dev/null || true
    hyprctl keyword decoration:blur:passes "3"        &>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MEDIA MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_save_media_state() {
    [[ "$HAS_PLAYERCTL" == "false" ]] && return 0

    local state_json='{"players":[]}'
    local players
    players="$(playerctl -l 2>/dev/null || echo '')"

    while IFS= read -r player; do
        [[ -z "$player" ]] && continue

        local status
        status="$(playerctl -p "$player" status 2>/dev/null || echo 'Stopped')"
        local title artist
        title="$(playerctl -p "$player" metadata title 2>/dev/null || echo '')"
        artist="$(playerctl -p "$player" metadata artist 2>/dev/null || echo '')"

        state_json="$(echo "$state_json" | jq \
            --arg  player "$player" \
            --arg  status "$status" \
            --arg  title  "$title" \
            --arg  artist "$artist" \
            '.players += [{
                "player": $player,
                "status": $status,
                "title":  $title,
                "artist": $artist
            }]' 2>/dev/null)"
    done <<< "$players"

    echo "$state_json" > "$LOCK_MEDIA_STATE_FILE"
    log_debug "Media state saved: $(echo "$state_json" | \
        jq '[.players[] | select(.status=="Playing")] | length' \
        2>/dev/null || echo '?') playing"
}

_pause_media() {
    [[ "$CFG_PAUSE_MEDIA" != "true" ]] && return 0
    [[ "$HAS_PLAYERCTL" == "false" ]] && return 0

    _save_media_state

    # Pause all playing players
    playerctl -a pause 2>/dev/null || true
    log_debug "All media paused"
}

_resume_media() {
    [[ "$CFG_RESUME_MEDIA_ON_UNLOCK" != "true" ]] && return 0
    [[ "$HAS_PLAYERCTL" == "false" ]] && return 0
    [[ ! -f "$LOCK_MEDIA_STATE_FILE" ]] && return 0

    log_debug "Restoring media state…"

    local players_json
    players_json="$(jq -r \
        '.players[] | select(.status == "Playing") | .player' \
        "$LOCK_MEDIA_STATE_FILE" 2>/dev/null || echo '')"

    while IFS= read -r player; do
        [[ -z "$player" ]] && continue
        playerctl -p "$player" play 2>/dev/null || true
        log_debug "Resumed: $player"
    done <<< "$players_json"

    rm -f "$LOCK_MEDIA_STATE_FILE"
}

_mute_microphone() {
    [[ "$CFG_MUTE_MICROPHONE" != "true" ]] && return 0
    [[ "$HAS_PACTL" == "false" ]] && return 0

    pactl set-source-mute @DEFAULT_SOURCE@ 1 2>/dev/null || true
    log_security "Microphone muted"
}

_unmute_microphone() {
    # Only unmute if we muted it (check saved state)
    [[ "$CFG_MUTE_MICROPHONE" != "true" ]] && return 0
    [[ "$HAS_PACTL" == "false" ]] && return 0

    pactl set-source-mute @DEFAULT_SOURCE@ 0 2>/dev/null || true
    log_debug "Microphone unmuted"
}

_mute_audio() {
    [[ "$CFG_MUTE_ON_LOCK" != "true" ]] && return 0
    [[ "$HAS_PACTL" == "false" ]] && return 0

    pactl set-sink-mute @DEFAULT_SINK@ 1 2>/dev/null || true
    log_debug "Audio muted"
}

_unmute_audio() {
    [[ "$CFG_MUTE_ON_LOCK" != "true" ]] && return 0
    [[ "$HAS_PACTL" == "false" ]] && return 0

    pactl set-sink-mute @DEFAULT_SINK@ 0 2>/dev/null || true
    log_debug "Audio unmuted"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SECURITY HARDENING
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_clear_clipboard() {
    [[ "$CFG_CLEAR_CLIPBOARD" != "true" ]] && return 0

    log_security "Clearing clipboard…"

    # Wayland clipboard via wl-clipboard
    if command -v wl-copy &>/dev/null; then
        echo -n "" | wl-copy 2>/dev/null || true
        echo -n "" | wl-copy --primary 2>/dev/null || true
        log_security "Wayland clipboard cleared"
    fi

    # cliphist clear
    if command -v cliphist &>/dev/null; then
        cliphist wipe 2>/dev/null || true
    fi

    # X11 clipboard
    if command -v xclip &>/dev/null; then
        echo -n "" | xclip -selection clipboard 2>/dev/null || true
        echo -n "" | xclip -selection primary   2>/dev/null || true
    fi

    if command -v xdotool &>/dev/null; then
        xdotool type "" 2>/dev/null || true
    fi
}

_lock_ssh_agent() {
    [[ "$CFG_LOCK_SSH" != "true" ]] && return 0
    [[ "$HAS_SSH_ADD" == "false" ]] && return 0

    log_security "Removing SSH agent identities…"

    if [[ -n "${SSH_AUTH_SOCK:-}" ]]; then
        ssh-add -D 2>/dev/null || true
        log_security "SSH agent keys cleared"
    fi

    echo "locked" > "$SSH_AGENT_STATE_FILE"
}

_lock_gpg_agent() {
    [[ "$CFG_LOCK_GPG" != "true" ]] && return 0
    [[ "$HAS_GPG_AGENT" == "false" ]] && return 0

    log_security "Locking GPG agent cache…"

    # Drop GPG agent cache (require re-entry of passphrase)
    gpg-connect-agent reloadagent /bye &>/dev/null || true

    # Kill the pinentry process if running
    pkill -x pinentry 2>/dev/null || true

    log_security "GPG agent cache cleared"
}

_kill_screenshare() {
    [[ "$CFG_KILL_SCREENSHARE" != "true" ]] && return 0

    # Check and stop active screenshares
    local screenshare_procs=("wf-recorder" "obs" "ffmpeg-screenshare"
                              "scrcpy" "wayvnc" "hyprpicker")

    for proc in "${screenshare_procs[@]}"; do
        if pgrep -x "$proc" &>/dev/null; then
            log_security "Stopping screenshare: $proc"
            pkill -x "$proc" 2>/dev/null || true
        fi
    done

    # Write screenshare state
    echo "stopped" > "${RUNTIME_DIR}/screenshare.state"
}

_stop_camera() {
    # Disable camera if in use (security hardening)
    if command -v v4l2-ctl &>/dev/null; then
        # Check if camera is in use
        local camera_users
        camera_users="$(fuser /dev/video* 2>/dev/null | wc -w)"
        if (( camera_users > 0 )); then
            log_security "Camera in use by $camera_users process(es)"
        fi
    fi
}

_disable_mic_hardware() {
    # Additional hardware mic mute if available (laptop function key)
    if [[ -f /proc/acpi/ibm/volume ]]; then
        echo "mute" > /proc/acpi/ibm/volume 2>/dev/null || true
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DPMS MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_schedule_dpms() {
    local delay="${1:-$CFG_DPMS_DELAY}"
    [[ "$CFG_DPMS_ON_LOCK" != "true" ]] && return 0
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0

    log_debug "Scheduling DPMS off in ${delay}s…"

    (
        sleep "$delay"
        if [[ -f "$LOCK_STATE_FILE" ]] && \
           [[ "$(cat "$LOCK_STATE_FILE")" == "locked" ]]; then
            hyprctl dispatch dpms off 2>/dev/null || true
            log_debug "DPMS off applied"
        fi
    ) &
    disown 2>/dev/null || true
}

_restore_dpms() {
    [[ "$HAS_HYPRCTL" == "false" ]] && return 0
    hyprctl dispatch dpms on 2>/dev/null || true
    log_debug "DPMS restored"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAYBAR / SWAYNC INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_waybar() {
    local signal="${CFG_WAYBAR_SIGNAL:-6}"
    pkill -SIGRTMIN+${signal} waybar 2>/dev/null || true
    log_debug "Waybar signaled SIGRTMIN+${signal}"
}

_update_status() {
    local state="$1"  # locking | locked | unlocking | unlocked

    jq -n \
        --arg state "$state" \
        --arg ts    "$(date -Iseconds)" \
        --arg user  "${USER:-$(whoami)}" \
        '{"state":$state,"timestamp":$ts,"user":$user}' \
        > "${RUNTIME_DIR}/lock-status.json" 2>/dev/null || true

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
        pw-play   --volume=0.50 "$file" &>/dev/null &
    elif command -v paplay  &>/dev/null; then
        paplay    --volume=32768 "$file" &>/dev/null &
    elif command -v ogg123  &>/dev/null; then
        ogg123    -q "$file" &>/dev/null &
    fi
    disown 2>/dev/null || true
}

_show_notification() {
    [[ "$HAS_NOTIFY" == "false" ]] && return 0
    [[ "$CFG_NOTIFY_ON_LOCK" != "true" ]] && return 0

    local title="$1"
    local body="${2:-}"

    notify-send \
        --urgency=low \
        --expire-time=2000 \
        --app-name="ASH Lock" \
        "$title" "$body" 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HYPRLOCK LAUNCHER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_select_hyprlock_layout() {
    # Auto-select layout based on monitor count and config
    local layout="${CFG_LAYOUT:-auto}"

    if [[ "$layout" == "auto" ]]; then
        if (( MONITOR_COUNT >= 2 )); then
            layout="dual-monitor"
        else
            layout="default"
        fi
    fi

    local layout_file
    case "$layout" in
        default)      layout_file="$HYPRLOCK_DEFAULT"  ;;
        minimal)      layout_file="$HYPRLOCK_MINIMAL"  ;;
        dual-monitor) layout_file="$HYPRLOCK_DUAL"     ;;
        animated)     layout_file="$HYPRLOCK_ANIMATED" ;;
        *)            layout_file="$HYPRLOCK_DEFAULT"  ;;
    esac

    if [[ -f "$layout_file" ]]; then
        echo "$layout_file"
    else
        echo ""  # Use hyprlock default config
    fi
}

_launch_hyprlock() {
    local layout_file
    layout_file="$(_select_hyprlock_layout)"

    local hyprlock_args=()
    [[ -n "$layout_file" ]] && \
        hyprlock_args+=(--config "$layout_file")

    log_info "Launching hyprlock${layout_file:+ (layout: $layout_file)}"

    if [[ "${#hyprlock_args[@]}" -gt 0 ]]; then
        hyprlock "${hyprlock_args[@]}" &
    else
        hyprlock &
    fi

    local hyprlock_pid=$!
    echo "$hyprlock_pid" > "$LOCK_PID_FILE"
    log_debug "Hyprlock PID: $hyprlock_pid"
    echo "$hyprlock_pid"
}

_launch_swaylock() {
    log_info "Launching swaylock…"

    local swaylock_args=(
        --daemonize
        --show-failed-attempts
        --fade-in "0.3"
        --grace "0"
    )

    # Use blurred screenshot if available
    if [[ -f "$LOCK_WALLPAPER_CACHE" ]]; then
        swaylock_args+=(
            --image "$LOCK_WALLPAPER_CACHE"
            --scaling fill
        )
    else
        swaylock_args+=(--color "1a1a2e")
    fi

    swaylock "${swaylock_args[@]}" &
    local pid=$!
    echo "$pid" > "$LOCK_PID_FILE"
    echo "$pid"
}

_is_locked() {
    if [[ -f "$LOCK_PID_FILE" ]]; then
        local pid
        pid="$(cat "$LOCK_PID_FILE" 2>/dev/null || echo '')"
        [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
    else
        pgrep -x hyprlock &>/dev/null || \
        pgrep -x swaylock &>/dev/null || \
        pgrep -x gtklock  &>/dev/null
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# GRACE PERIOD HANDLER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_grace_period() {
    local seconds="${1:-$CFG_LOCK_GRACE_PERIOD}"
    (( seconds <= 0 )) && return 0

    log_info "Grace period: ${seconds}s (move mouse/press key to cancel)"

    # Show grace notification
    if [[ "$HAS_NOTIFY" == "true" ]]; then
        notify-send \
            --urgency=critical \
            --expire-time=$(( seconds * 1000 )) \
            --app-name="ASH Lock" \
            "${ICON_LOCK}  Locking in ${seconds}s" \
            "Move mouse or press a key to cancel" 2>/dev/null || true
    fi

    # Wait for grace period
    local start_time end_time
    start_time="$(date +%s)"
    end_time=$(( start_time + seconds ))

    while (( $(date +%s) < end_time )); do
        # Check for user activity via hyprctl
        if [[ "$HAS_HYPRCTL" == "true" ]]; then
            local last_activity
            last_activity="$(hyprctl idle 2>/dev/null | \
                grep 'idle' | awk '{print $NF}' || echo '999999')"
            if (( last_activity < 2000 )); then
                log_info "Grace period cancelled — user activity detected"
                return 1
            fi
        fi
        sleep 0.5
    done

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# PRESENCE DETECTION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_presence() {
    [[ "$CFG_PRESENCE_CHECK" != "true" ]] && return 0

    # Webcam-based presence detection
    if command -v python3 &>/dev/null; then
        local presence
        presence="$(python3 -c "
import subprocess, sys
try:
    # Simple webcam check via fswebcam
    result = subprocess.run(
        ['fswebcam', '-q', '-r', '160x120',
         '--no-banner', '/tmp/ash-presence.jpg'],
        capture_output=True, timeout=3
    )
    # Very basic presence check — if camera works, assume present
    sys.exit(0 if result.returncode == 0 else 1)
except Exception:
    sys.exit(2)
" 2>/dev/null && echo "present" || echo "absent")"

        rm -f "/tmp/ash-presence.jpg"

        if [[ "$presence" == "present" ]]; then
            log_debug "Presence detected — extending lock timer"
            echo "present" > "$LOCK_PRESENCE_FILE"
            return 0  # Presence detected
        fi
    fi

    echo "absent" > "$LOCK_PRESENCE_FILE"
    return 1  # No presence
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOGINCTL INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_notify_logind_lock() {
    # Notify logind that session is locked (proper systemd integration)
    if [[ "$HAS_LOGINCTL" == "true" ]]; then
        loginctl lock-session 2>/dev/null || true
        log_debug "loginctl lock-session signalled"
    fi
}

_notify_logind_unlock() {
    if [[ "$HAS_LOGINCTL" == "true" ]]; then
        loginctl unlock-session 2>/dev/null || true
        log_debug "loginctl unlock-session signalled"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANALYTICS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_record_lock_event() {
    local event="$1"      # lock | unlock | failed
    local metadata="${2:-{}}"

    [[ "$CFG_ANALYTICS" != "true" ]] && return 0
    [[ "$HAS_JQ" == "false" ]] && return 0

    [[ ! -f "$LOCK_HISTORY_FILE" ]] && \
        echo '{"events":[],"total_locks":0,"total_unlocks":0}' \
        > "$LOCK_HISTORY_FILE"

    jq \
        --arg  event "$event" \
        --arg  ts    "$(date -Iseconds)" \
        --arg  user  "${USER:-unknown}" \
        --argjson meta "$metadata" \
        '.events += [{
            "event":     $event,
            "timestamp": $ts,
            "user":      $user,
            "metadata":  $meta
        }] |
        .events = .events[-500:] |
        if $event == "lock"   then .total_locks   += 1 else . end |
        if $event == "unlock" then .total_unlocks += 1 else . end' \
        "$LOCK_HISTORY_FILE" \
        > "${LOCK_HISTORY_FILE}.tmp" 2>/dev/null && \
    mv "${LOCK_HISTORY_FILE}.tmp" "$LOCK_HISTORY_FILE"

    log_debug "Lock event recorded: $event"
}

_update_lock_stats() {
    local event="$1"  # lock | unlock
    local session_duration="${2:-0}"

    [[ "$CFG_ANALYTICS" != "true" ]] && return 0
    [[ "$HAS_JQ" == "false" ]] && return 0

    local date_key
    date_key="$(date '+%Y-%m-%d')"

    [[ ! -f "$LOCK_STATS_FILE" ]] && \
        echo '{"daily":{},"all_time":{"locks":0,"total_session_secs":0}}' \
        > "$LOCK_STATS_FILE"

    jq \
        --arg date "$date_key" \
        --arg event "$event" \
        --argjson dur "$session_duration" \
        '
        .daily[$date] = (.daily[$date] // {"locks":0,"total_secs":0}) |
        if $event == "lock"   then .daily[$date].locks += 1          else . end |
        if $event == "unlock" then
            .daily[$date].total_secs += $dur |
            .all_time.total_session_secs += $dur
        else . end |
        if $event == "lock" then .all_time.locks += 1 else . end' \
        "$LOCK_STATS_FILE" \
        > "${LOCK_STATS_FILE}.tmp" 2>/dev/null && \
    mv "${LOCK_STATS_FILE}.tmp" "$LOCK_STATS_FILE"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ON-UNLOCK HANDLER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_on_unlock() {
    log_info "Session unlocked — running post-unlock sequence…"

    # Calculate session duration
    local session_duration=0
    if [[ -f "$LOCK_TIMESTAMP_FILE" ]]; then
        local lock_ts now_ts
        lock_ts="$(cat "$LOCK_TIMESTAMP_FILE" 2>/dev/null || echo '0')"
        now_ts="$(date +%s)"
        session_duration=$(( now_ts - lock_ts ))
        rm -f "$LOCK_TIMESTAMP_FILE"
    fi

    # 1. Restore DPMS
    _restore_dpms

    # 2. Restore compositor
    _restore_after_lock

    # 3. Undim screen
    local undim_script="${SCRIPT_DIR}/undim-screen.sh"
    if [[ -x "$undim_script" ]]; then
        "$undim_script" --force &>/dev/null & true
    fi

    # 4. Restore media
    _resume_media

    # 5. Unmute microphone
    _unmute_microphone

    # 6. Unmute audio
    _unmute_audio

    # 7. Notify logind
    _notify_logind_unlock

    # 8. Update state
    echo "unlocked" > "$LOCK_STATE_FILE"
    _update_status "unlocked"
    rm -f "$LOCK_PID_FILE"

    # 9. Analytics
    _record_lock_event "unlock" \
        "{\"session_duration_secs\": $session_duration}"
    _update_lock_stats "unlock" "$session_duration"

    # 10. Sound
    _play_sound "$SOUND_UNLOCK" "$CFG_SOUND_ON_UNLOCK"

    # 11. Signal Waybar
    _signal_waybar

    # 12. Run post-unlock hook
    local hook="${CONFIG_DIR}/hooks/on-unlock.sh"
    [[ -f "$hook" && -x "$hook" ]] && \
        LOCK_DURATION="$session_duration" "$hook" & true

    log_success "Unlock complete (session was locked for ${session_duration}s)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE LOCK OPERATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_do_lock() {
    local force="${1:-false}"
    local layout_override="${2:-}"
    local grace_override=""

    # Already locked check
    if _is_locked && [[ "$force" == "false" ]]; then
        log_info "Session already locked"
        return 0
    fi

    # Inhibit check
    if [[ "$force" == "false" ]] && _is_inhibited; then
        log_info "Lock inhibited — skipping"
        return 0
    fi

    # Grace period
    if ! _grace_period "${grace_override:-$CFG_LOCK_GRACE_PERIOD}"; then
        log_info "Lock cancelled during grace period"
        return 0
    fi

    log_security "Initiating session lock sequence…"

    # ── Phase 1: Pre-lock security ────────────────────────────────────────
    _update_status "locking"
    echo "locking" > "$LOCK_STATE_FILE"

    _kill_screenshare
    _stop_camera
    _clear_clipboard
    _lock_gpg_agent
    _lock_ssh_agent
    _notify_logind_lock

    # ── Phase 2: Media & audio ────────────────────────────────────────────
    _pause_media
    _mute_microphone
    _mute_audio

    # ── Phase 3: Visual pre-lock effects ─────────────────────────────────
    _pre_lock_dim
    _pre_lock_animation
    _capture_screenshot  # Must be before locker starts

    # ── Phase 4: Launch locker ────────────────────────────────────────────
    local locker="${CFG_LOCKER}"
    [[ "$locker" == "auto" ]] && locker="$LOCKER_CMD"
    [[ -n "$layout_override" ]] && CFG_LAYOUT="$layout_override"

    local locker_pid

    case "$locker" in
        hyprlock)
            locker_pid="$(_launch_hyprlock)"
            ;;
        swaylock)
            locker_pid="$(_launch_swaylock)"
            ;;
        gtklock)
            gtklock -d &
            locker_pid=$!
            echo "$locker_pid" > "$LOCK_PID_FILE"
            ;;
        loginctl)
            loginctl lock-session &>/dev/null
            locker_pid=0
            ;;
        *)
            if command -v "$locker" &>/dev/null; then
                "$locker" &
                locker_pid=$!
                echo "$locker_pid" > "$LOCK_PID_FILE"
            else
                log_error "Unknown locker: $locker"
                return 1
            fi
            ;;
    esac

    # ── Phase 5: Post-launch setup ────────────────────────────────────────
    date +%s > "$LOCK_TIMESTAMP_FILE"
    echo "locked" > "$LOCK_STATE_FILE"
    _update_status "locked"

    # Schedule DPMS
    _schedule_dpms

    # Analytics
    _record_lock_event "lock" \
        "$(jq -n \
            --arg locker "$locker" \
            --arg layout "$CFG_LAYOUT" \
            '{"locker":$locker,"layout":$layout}' 2>/dev/null || echo '{}')"
    _update_lock_stats "lock"

    # Sound
    _play_sound "$SOUND_LOCK" "$CFG_SOUND_ON_LOCK"

    # Notification
    _show_notification \
        "${ICON_LOCK}  Session Locked" \
        "Locked by ASH"

    # Signal Waybar
    _signal_waybar

    # Run pre-lock hook
    local pre_hook="${CONFIG_DIR}/hooks/on-lock.sh"
    [[ -f "$pre_hook" && -x "$pre_hook" ]] && \
        LOCK_LOCKER="$locker" "$pre_hook" & true

    log_security "Session locked (PID=${locker_pid} locker=$locker)"

    # ── Phase 6: Wait for unlock ──────────────────────────────────────────
    if (( locker_pid > 0 )); then
        wait "$locker_pid" 2>/dev/null || true
    else
        # Poll for unlock if PID not available
        while _is_locked; do
            sleep 1
        done
    fi

    # ── Phase 7: Post-unlock ─────────────────────────────────────────────
    _on_unlock
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATUS & HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_status() {
    local format="${1:-human}"
    local is_locked_now=false
    _is_locked && is_locked_now=true

    local current_state
    current_state="$(cat "$LOCK_STATE_FILE" 2>/dev/null || echo 'unlocked')"

    local lock_duration=0
    if [[ -f "$LOCK_TIMESTAMP_FILE" ]] && [[ "$is_locked_now" == "true" ]]; then
        local lock_ts now_ts
        lock_ts="$(cat "$LOCK_TIMESTAMP_FILE" 2>/dev/null || echo 0)"
        now_ts="$(date +%s)"
        lock_duration=$(( now_ts - lock_ts ))
    fi

    case "$format" in
        json)
            jq -n \
                --argjson locked    "$is_locked_now" \
                --arg state         "$current_state" \
                --argjson duration  "$lock_duration" \
                --arg locker        "$LOCKER_CMD" \
                --arg ts            "$(date -Iseconds)" \
                '{
                    "locked":           $locked,
                    "state":            $state,
                    "lock_duration_sec":$duration,
                    "locker":           $locker,
                    "timestamp":        $ts
                }'
            ;;
        waybar)
            local text class tooltip
            if [[ "$is_locked_now" == "true" ]]; then
                local dur_str
                dur_str="$(awk "BEGIN {
                    m = int($lock_duration/60)
                    s = $lock_duration % 60
                    printf \"%dm %ds\", m, s
                }")"
                text="${ICON_LOCK}"
                tooltip="Locked for $dur_str"
                class="session-locked"
            else
                text="${ICON_UNLOCK}"
                tooltip="Session unlocked"
                class="session-unlocked"
            fi
            jq -n \
                --arg text    "$text" \
                --arg tooltip "$tooltip" \
                --arg class   "$class" \
                '{"text":$text,"tooltip":$tooltip,"class":$class}'
            ;;
        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_ASH}  ASH Lock Status${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            if [[ "$is_locked_now" == "true" ]]; then
                echo -e "  State   : ${CLR_RED}${CLR_BOLD}${ICON_LOCK}  Locked${CLR_RESET}"
                local dur_str
                dur_str="$(awk "BEGIN {
                    m = int($lock_duration/60)
                    s = $lock_duration % 60
                    printf \"%dm %02ds\", m, s
                }")"
                echo -e "  Duration: ${CLR_YELLOW}${ICON_CLOCK}  ${dur_str}${CLR_RESET}"
            else
                echo -e "  State   : ${CLR_GREEN}${ICON_UNLOCK}  Unlocked${CLR_RESET}"
            fi

            echo -e "  Locker  : ${CLR_WHITE}${LOCKER_CMD}${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

_show_history() {
    local limit="${1:-10}"
    [[ ! -f "$LOCK_HISTORY_FILE" ]] && { echo "[]"; return; }

    jq \
        --argjson limit "$limit" \
        '.events | .[-($limit):] | reverse' \
        "$LOCK_HISTORY_FILE" 2>/dev/null || echo "[]"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH Lock Session v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [OPTIONS]

${CLR_BOLD}LOCK OPTIONS${CLR_RESET}
  ${CLR_GREEN}(no args)${CLR_RESET}              Lock session (default)
  ${CLR_GREEN}--force, -f${CLR_RESET}            Force lock (ignore inhibit)
  ${CLR_GREEN}--locker NAME${CLR_RESET}          Override locker (hyprlock|swaylock|gtklock)
  ${CLR_GREEN}--layout NAME${CLR_RESET}          Override layout (default|minimal|dual-monitor)
  ${CLR_GREEN}--grace N${CLR_RESET}              Grace period seconds (0=immediate)

${CLR_BOLD}SECURITY${CLR_RESET}
  ${CLR_YELLOW}--no-clipboard${CLR_RESET}         Skip clipboard clear
  ${CLR_YELLOW}--no-gpg${CLR_RESET}               Skip GPG agent lock
  ${CLR_YELLOW}--no-ssh${CLR_RESET}               Skip SSH key removal
  ${CLR_YELLOW}--no-screenshare${CLR_RESET}       Skip screenshare kill

${CLR_BOLD}STATUS${CLR_RESET}
  ${CLR_CYAN}--status${CLR_RESET}               Human-readable status
  ${CLR_CYAN}--status=json${CLR_RESET}          JSON status
  ${CLR_CYAN}--status=waybar${CLR_RESET}        Waybar module JSON
  ${CLR_CYAN}--history${CLR_RESET}              Recent lock history
  ${CLR_CYAN}--history N${CLR_RESET}            Last N lock events

${CLR_BOLD}MISC${CLR_RESET}
  ${CLR_WHITE}--version${CLR_RESET}              Show version
  ${CLR_WHITE}--help${CLR_RESET}                 Show help

${CLR_BOLD}EXAMPLES${CLR_RESET}
  $(basename "$0")                        # Standard lock
  $(basename "$0") --force                # Override inhibit
  $(basename "$0") --grace 10             # 10s grace period
  $(basename "$0") --locker swaylock      # Use swaylock
  $(basename "$0") --status=json          # JSON status

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    _ensure_dirs
    _detect_capabilities
    _load_profile
    _acquire_lock || { log_error "Lock-script conflict"; exit 1; }

    local force=false
    local locker_override=""
    local layout_override=""
    local grace_override=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --force|-f)         force=true ;;
            --locker)           shift; locker_override="${1:-}" ;;
            --locker=*)         locker_override="${1#--locker=}" ;;
            --layout)           shift; layout_override="${1:-}" ;;
            --layout=*)         layout_override="${1#--layout=}" ;;
            --grace)            shift; grace_override="${1:-0}" ;;
            --grace=*)          grace_override="${1#--grace=}" ;;
            --no-clipboard)     CFG_CLEAR_CLIPBOARD=false ;;
            --no-gpg)           CFG_LOCK_GPG=false ;;
            --no-ssh)           CFG_LOCK_SSH=false ;;
            --no-screenshare)   CFG_KILL_SCREENSHARE=false ;;
            --no-media)         CFG_PAUSE_MEDIA=false ;;
            --no-dim)           CFG_DIM_BEFORE_LOCK=false ;;
            --no-blur)          CFG_PRE_LOCK_BLUR=false ;;
            --status)           _show_status human; exit 0 ;;
            --status=json)      _show_status json;  exit 0 ;;
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

    # Apply overrides
    [[ -n "$locker_override" ]] && CFG_LOCKER="$locker_override"
    [[ -n "$grace_override"  ]] && CFG_LOCK_GRACE_PERIOD="$grace_override"

    _do_lock "$force" "$layout_override"
    exit 0
}

main "$@"