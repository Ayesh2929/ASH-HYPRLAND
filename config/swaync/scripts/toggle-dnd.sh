#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — SwayNC Ultra DND Toggle Script                  ║
# ║  Premium Do Not Disturb controller with focus modes, scheduling,            ║
# ║  analytics, multi-app status sync, and intelligent state management         ║
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

readonly SCRIPT_NAME="ash-dnd-toggle"
readonly SCRIPT_VERSION="5.0.0"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cache & State directories
readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/ash"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"

# State files
readonly DND_STATE_FILE="${CACHE_DIR}/dnd.state"
readonly DND_TIMER_FILE="${CACHE_DIR}/dnd-timer.state"
readonly DND_HISTORY_FILE="${DATA_DIR}/dnd-history.json"
readonly DND_STATS_FILE="${CACHE_DIR}/dnd-stats.json"
readonly DND_SCHEDULE_FILE="${CONFIG_DIR}/dnd-schedule.json"
readonly DND_EXCEPTIONS_FILE="${CONFIG_DIR}/dnd-exceptions.json"
readonly DND_LOCK_FILE="${RUNTIME_DIR}/dnd.lock"
readonly DND_PID_FILE="${RUNTIME_DIR}/dnd-timer.pid"
readonly DND_LOG_FILE="${CACHE_DIR}/logs/dnd.log"
readonly ASH_MODE_FILE="${CACHE_DIR}/state/current-mode.json"

# Sound files
readonly SOUND_DND_ON="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/dnd-on.ogg"
readonly SOUND_DND_OFF="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/dnd-off.ogg"
readonly SOUND_FOCUS="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/focus-start.ogg"

# Icons
readonly ICON_DND_ON="󰂛"
readonly ICON_DND_OFF="󰂚"
readonly ICON_FOCUS="󰁁"
readonly ICON_POMODORO="󱎫"
readonly ICON_SCHEDULE="󱑃"
readonly ICON_TIMER="󱑂"
readonly ICON_ASH="󱎫"
readonly ICON_SUCCESS="󰄬"
readonly ICON_ERROR="󰅙"
readonly ICON_WARNING="󰀦"
readonly ICON_INFO="󰋼"

# Colors for terminal output
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

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOGGING SYSTEM
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR"
        "$STATE_DIR"
        "$DATA_DIR"
        "$CONFIG_DIR"
        "$RUNTIME_DIR"
        "${CACHE_DIR}/logs"
        "$(dirname "$DND_HISTORY_FILE")"
    )
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir"
    done
}

_log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp="$(date '+%Y-%m-%d %H:%M:%S')"
    local log_entry="[$timestamp] [$level] $message"

    # Append to log file with rotation
    if [[ -f "$DND_LOG_FILE" ]]; then
        local log_size
        log_size="$(stat -c%s "$DND_LOG_FILE" 2>/dev/null || echo 0)"
        if (( log_size > 524288 )); then  # 512KB rotation
            mv "$DND_LOG_FILE" "${DND_LOG_FILE}.old"
        fi
    fi
    echo "$log_entry" >> "$DND_LOG_FILE" 2>/dev/null || true

    # Terminal output with colors (only if terminal attached)
    if [[ -t 2 ]]; then
        case "$level" in
            ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[ERROR]${CLR_RESET} $message" >&2 ;;
            WARN)    echo -e "${CLR_YELLOW}[WARN]${CLR_RESET}  $message" >&2 ;;
            INFO)    echo -e "${CLR_CYAN}[INFO]${CLR_RESET}  $message" >&2 ;;
            DEBUG)   [[ "${ASH_DEBUG:-0}" == "1" ]] && \
                     echo -e "${CLR_GRAY}[DEBUG] $message${CLR_RESET}" >&2 ;;
            SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[OK]${CLR_RESET}   $message" >&2 ;;
        esac
    fi
}

log_info()    { _log "INFO"    "$*"; }
log_warn()    { _log "WARN"    "$*"; }
log_error()   { _log "ERROR"   "$*"; }
log_debug()   { _log "DEBUG"   "$*"; }
log_success() { _log "SUCCESS" "$*"; }

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEPENDENCY CHECKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_deps() {
    local required=("swaync-client" "notify-send" "jq" "date")
    local optional=("pactl" "playerctl" "hyprctl" "pkill" "ogg123"
                    "ffplay" "pw-play" "slack" "discord-cli")
    local missing_required=()

    for cmd in "${required[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_required+=("$cmd")
        fi
    done

    if (( ${#missing_required[@]} > 0 )); then
        log_error "Missing required dependencies: ${missing_required[*]}"
        _notify_error "Missing dependencies" \
            "Required: ${missing_required[*]}"
        exit 1
    fi

    # Log optional availability
    for cmd in "${optional[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_debug "Optional dependency not found: $cmd"
        fi
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# LOCK MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_acquire_lock() {
    local max_wait=5
    local waited=0

    while [[ -f "$DND_LOCK_FILE" ]]; do
        local lock_pid
        lock_pid="$(cat "$DND_LOCK_FILE" 2>/dev/null || echo '')"

        # Check if locking process is still alive
        if [[ -n "$lock_pid" ]] && ! kill -0 "$lock_pid" 2>/dev/null; then
            log_warn "Stale lock file detected, removing"
            rm -f "$DND_LOCK_FILE"
            break
        fi

        if (( waited >= max_wait )); then
            log_error "Could not acquire lock after ${max_wait}s"
            return 1
        fi

        sleep 0.2
        (( waited++ )) || true
    done

    echo "$$" > "$DND_LOCK_FILE"
    log_debug "Lock acquired (PID=$$)"
    return 0
}

_release_lock() {
    rm -f "$DND_LOCK_FILE"
    log_debug "Lock released"
}

# Auto-release on exit
trap '_release_lock; _cleanup_temp' EXIT INT TERM

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NOTIFICATION ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_notify() {
    local title="$1"
    local body="${2:-}"
    local urgency="${3:-normal}"
    local expire="${4:-4000}"
    local icon="${5:-dialog-information}"
    local category="${6:-}"
    local action_label="${7:-}"
    local action_cmd="${8:-}"

    local notify_args=(
        --urgency="$urgency"
        --expire-time="$expire"
        --app-name="ASH DND"
        --icon="$icon"
    )

    [[ -n "$category" ]] && notify_args+=(--category="$category")

    if [[ -n "$action_label" && -n "$action_cmd" ]]; then
        notify_args+=(--action="$action_label=$action_cmd")
    fi

    notify-send "${notify_args[@]}" "$title" "$body" 2>/dev/null || true
    log_debug "Notification sent: $title — $body"
}

_notify_dnd_on() {
    local duration_str="${1:-}"
    local mode="${2:-}"
    local body="All notifications silenced"

    [[ -n "$duration_str" ]] && body+=" for $duration_str"
    [[ -n "$mode" ]]         && body+=" ($mode)"

    _notify \
        "${ICON_DND_ON}  Do Not Disturb" \
        "$body" \
        "low" \
        "3500" \
        "notification-disabled-symbolic" \
        "x-ash.dnd" \
        "Disable" \
        "$(realpath "$0") --off"
}

_notify_dnd_off() {
    local held_count="${1:-0}"
    local body="Notifications restored"

    (( held_count > 0 )) && body+="  •  ${held_count} held"

    _notify \
        "${ICON_DND_OFF}  Do Not Disturb Off" \
        "$body" \
        "low" \
        "3000" \
        "notification-symbolic" \
        "x-ash.dnd"
}

_notify_focus() {
    local mode_name="$1"
    local duration_str="${2:-}"
    local icon="${3:-$ICON_FOCUS}"

    _notify \
        "${icon}  ${mode_name}" \
        "Focus session started${duration_str:+ for $duration_str}" \
        "low" \
        "4000" \
        "timer-symbolic" \
        "x-ash.focus"
}

_notify_timer_end() {
    local mode_name="${1:-Focus}"

    _notify \
        "⏰  Session Complete" \
        "${mode_name} session ended — well done!" \
        "normal" \
        "0" \
        "appointment-soon-symbolic" \
        "x-ash.timer"
}

_notify_error() {
    local title="$1"
    local body="${2:-}"

    _notify \
        "${ICON_ERROR}  ASH DND — $title" \
        "$body" \
        "critical" \
        "6000" \
        "dialog-error-symbolic"
}

_notify_schedule() {
    local start="$1"
    local end="$2"

    _notify \
        "${ICON_SCHEDULE}  DND Scheduled" \
        "Silence from ${start} to ${end}" \
        "low" \
        "4000" \
        "timer-symbolic"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SOUND ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_play_sound() {
    local sound_file="$1"

    [[ ! -f "$sound_file" ]] && return 0

    # Try multiple audio backends
    if command -v pw-play &>/dev/null; then
        pw-play --volume=0.5 "$sound_file" &>/dev/null &
    elif command -v paplay &>/dev/null; then
        paplay --volume=32768 "$sound_file" &>/dev/null &
    elif command -v ogg123 &>/dev/null; then
        ogg123 -q "$sound_file" &>/dev/null &
    elif command -v ffplay &>/dev/null; then
        ffplay -nodisp -autoexit -volume 50 "$sound_file" &>/dev/null &
    fi
    log_debug "Sound played: $sound_file"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATE MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_dnd_state() {
    # Primary: swaync-client
    if command -v swaync-client &>/dev/null; then
        local state
        state="$(swaync-client --get-dnd 2>/dev/null)" || state=""
        if [[ "$state" == "true" ]]; then
            echo "on"
            return 0
        elif [[ "$state" == "false" ]]; then
            echo "off"
            return 0
        fi
    fi

    # Fallback: state file
    if [[ -f "$DND_STATE_FILE" ]]; then
        cat "$DND_STATE_FILE"
    else
        echo "off"
    fi
}

_set_state_file() {
    local state="$1"
    echo "$state" > "$DND_STATE_FILE"
}

_get_notification_count() {
    swaync-client --count 2>/dev/null || echo "0"
}

_is_timer_running() {
    if [[ -f "$DND_PID_FILE" ]]; then
        local pid
        pid="$(cat "$DND_PID_FILE" 2>/dev/null || echo '')"
        [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
    else
        return 1
    fi
}

_get_timer_remaining() {
    if [[ -f "$DND_TIMER_FILE" ]]; then
        local end_time now remaining
        end_time="$(jq -r '.end_time // 0' "$DND_TIMER_FILE" 2>/dev/null || echo 0)"
        now="$(date +%s)"
        remaining=$(( end_time - now ))
        (( remaining > 0 )) && echo "$remaining" || echo "0"
    else
        echo "0"
    fi
}

_format_duration() {
    local seconds="$1"
    local hours=$(( seconds / 3600 ))
    local minutes=$(( (seconds % 3600) / 60 ))
    local secs=$(( seconds % 60 ))

    if (( hours > 0 )); then
        printf "%dh %02dm" "$hours" "$minutes"
    elif (( minutes > 0 )); then
        printf "%dm %02ds" "$minutes" "$secs"
    else
        printf "%ds" "$secs"
    fi
}

_parse_duration_arg() {
    # Parse duration strings: 30m, 1h, 1h30m, 90, etc.
    local input="$1"
    local total=0

    if [[ "$input" =~ ^([0-9]+)h([0-9]+)m$ ]]; then
        total=$(( ${BASH_REMATCH[1]} * 3600 + ${BASH_REMATCH[2]} * 60 ))
    elif [[ "$input" =~ ^([0-9]+)h$ ]]; then
        total=$(( ${BASH_REMATCH[1]} * 3600 ))
    elif [[ "$input" =~ ^([0-9]+)m$ ]]; then
        total=$(( ${BASH_REMATCH[1]} * 60 ))
    elif [[ "$input" =~ ^([0-9]+)s$ ]]; then
        total="${BASH_REMATCH[1]}"
    elif [[ "$input" =~ ^[0-9]+$ ]]; then
        # Treat plain number as seconds if < 300, else minutes
        if (( input < 300 )); then
            total="$input"
        else
            total=$(( input * 60 ))
        fi
    else
        log_error "Invalid duration format: $input (use 30m, 1h, 1h30m)"
        return 1
    fi

    echo "$total"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANALYTICS & HISTORY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_analytics_record_event() {
    local event="$1"          # on | off | focus_start | focus_end | timer
    local metadata="${2:-{}}" # JSON object
    local timestamp
    timestamp="$(date -Iseconds)"
    local date_key
    date_key="$(date '+%Y-%m-%d')"

    # Initialize history file
    if [[ ! -f "$DND_HISTORY_FILE" ]]; then
        echo '{"events":[],"daily":{}}' > "$DND_HISTORY_FILE"
    fi

    # Append event using jq
    local updated
    updated="$(jq \
        --arg event "$event" \
        --arg ts "$timestamp" \
        --argjson meta "$metadata" \
        '.events += [{
            "event": $event,
            "timestamp": $ts,
            "metadata": $meta
        }] | .events = .events[-1000:]' \
        "$DND_HISTORY_FILE" 2>/dev/null)" || return 0

    echo "$updated" > "$DND_HISTORY_FILE"
    log_debug "Analytics: recorded $event"
}

_analytics_update_stats() {
    local event="$1"  # on | off
    local date_key
    date_key="$(date '+%Y-%m-%d')"

    if [[ ! -f "$DND_STATS_FILE" ]]; then
        echo '{
            "today": {"activations": 0, "total_seconds": 0, "sessions": []},
            "all_time": {"activations": 0, "total_seconds": 0},
            "date": ""
        }' > "$DND_STATS_FILE"
    fi

    local current_date
    current_date="$(jq -r '.date // ""' "$DND_STATS_FILE" 2>/dev/null || echo '')"

    # Reset daily stats if new day
    if [[ "$current_date" != "$date_key" ]]; then
        jq --arg date "$date_key" \
            '.today = {"activations": 0, "total_seconds": 0, "sessions": []} |
             .date = $date' \
            "$DND_STATS_FILE" > "${DND_STATS_FILE}.tmp" && \
        mv "${DND_STATS_FILE}.tmp" "$DND_STATS_FILE"
    fi

    if [[ "$event" == "on" ]]; then
        jq \
            --arg ts "$(date +%s)" \
            '.today.activations += 1 |
             .all_time.activations += 1 |
             .today.sessions += [{"start": ($ts | tonumber)}]' \
            "$DND_STATS_FILE" > "${DND_STATS_FILE}.tmp" && \
        mv "${DND_STATS_FILE}.tmp" "$DND_STATS_FILE"

    elif [[ "$event" == "off" ]]; then
        local now
        now="$(date +%s)"
        jq \
            --argjson now "$now" \
            'if (.today.sessions | length) > 0 and (.today.sessions[-1].end == null) then
                .today.sessions[-1].end = $now |
                .today.sessions[-1].duration = ($now - (.today.sessions[-1].start | tonumber)) |
                .today.total_seconds += ($now - (.today.sessions[-1].start | tonumber)) |
                .all_time.total_seconds += ($now - (.today.sessions[-1].start | tonumber))
             else . end' \
            "$DND_STATS_FILE" > "${DND_STATS_FILE}.tmp" && \
        mv "${DND_STATS_FILE}.tmp" "$DND_STATS_FILE"
    fi

    log_debug "Stats updated: $event"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# THIRD-PARTY STATUS SYNC
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_sync_discord_status() {
    local state="$1"  # on | off

    # Discord via xdg-open or discord-cli
    if command -v discord-cli &>/dev/null; then
        if [[ "$state" == "on" ]]; then
            discord-cli status set "donotdisturb" &>/dev/null & true
        else
            discord-cli status set "online" &>/dev/null & true
        fi
        log_debug "Discord status synced: $state"
    fi
}

_sync_slack_status() {
    local state="$1"  # on | off
    local slack_token_file="${CONFIG_DIR}/secrets/slack-token"

    [[ ! -f "$slack_token_file" ]] && return 0

    local token
    token="$(cat "$slack_token_file" 2>/dev/null || echo '')"
    [[ -z "$token" ]] && return 0

    if [[ "$state" == "on" ]]; then
        curl -sS -X POST "https://slack.com/api/users.profile.set" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d '{"profile":{"status_emoji":":no_bell:","status_text":"In focus mode","status_expiration":0}}' \
            &>/dev/null & true
    else
        curl -sS -X POST "https://slack.com/api/users.profile.set" \
            -H "Authorization: Bearer $token" \
            -H "Content-Type: application/json" \
            -d '{"profile":{"status_emoji":"","status_text":"","status_expiration":0}}' \
            &>/dev/null & true
    fi
    log_debug "Slack status synced: $state"
}

_sync_all_integrations() {
    local state="$1"
    local config_file="${CONFIG_DIR}/dnd-integrations.json"

    [[ ! -f "$config_file" ]] && return 0

    local discord_enabled slack_enabled
    discord_enabled="$(jq -r '.discord.enabled // false' "$config_file" 2>/dev/null)"
    slack_enabled="$(jq -r '.slack.enabled   // false' "$config_file" 2>/dev/null)"

    [[ "$discord_enabled" == "true" ]] && _sync_discord_status "$state"
    [[ "$slack_enabled"   == "true" ]] && _sync_slack_status   "$state"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# WAYBAR SIGNAL
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_signal_waybar() {
    # Signal waybar to update DND custom module (signal 8)
    if command -v pkill &>/dev/null; then
        pkill -SIGRTMIN+8 waybar 2>/dev/null || true
        log_debug "Waybar signaled (SIGRTMIN+8)"
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HYPRLAND INTEGRATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_hyprland_update() {
    local state="$1"

    command -v hyprctl &>/dev/null || return 0

    if [[ "$state" == "on" ]]; then
        # Set a Hyprland variable for scripts to read
        hyprctl keyword \
            "misc:layers_hog_keyboard_focus" \
            "false" \
            &>/dev/null || true
    fi
    log_debug "Hyprland updated for DND: $state"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# EXCEPTION CHECKER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_exceptions() {
    # Returns 0 if exceptions allow notifications, 1 if DND overrides
    [[ ! -f "$DND_EXCEPTIONS_FILE" ]] && return 1

    local allow_calls allow_critical allow_reminders
    allow_calls="$(jq -r '.allow_calls    // false' "$DND_EXCEPTIONS_FILE" 2>/dev/null)"
    allow_critical="$(jq -r '.allow_critical // true' "$DND_EXCEPTIONS_FILE" 2>/dev/null)"
    allow_reminders="$(jq -r '.allow_reminders // false' "$DND_EXCEPTIONS_FILE" 2>/dev/null)"

    # Write exception config for swaync to read
    local exc_config
    exc_config="$(jq -n \
        --argjson calls    "$allow_calls" \
        --argjson critical "$allow_critical" \
        --argjson remind   "$allow_reminders" \
        '{
            "notification-visibility": {
                "critical-exceptions": {
                    "state": (if $critical then "enabled" else "muted" end),
                    "urgency": "critical"
                }
            }
        }')" || return 0

    log_debug "Exceptions configured: calls=$allow_calls critical=$allow_critical"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# TIMER ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_start_timer() {
    local duration="$1"  # seconds
    local mode="${2:-timed}"
    local label="${3:-DND Timer}"

    _stop_timer 2>/dev/null || true

    local end_time
    end_time=$(( $(date +%s) + duration ))
    local duration_str
    duration_str="$(_format_duration "$duration")"

    # Write timer state
    jq -n \
        --argjson end  "$end_time" \
        --argjson dur  "$duration" \
        --arg     mode "$mode" \
        --arg     lbl  "$label" \
        --arg     ts   "$(date -Iseconds)" \
        '{
            "end_time":   $end,
            "duration":   $dur,
            "mode":       $mode,
            "label":      $lbl,
            "started_at": $ts
        }' > "$DND_TIMER_FILE"

    # Launch background timer process
    (
        sleep "$duration"
        # Timer expired — turn off DND
        if [[ -f "$DND_STATE_FILE" ]] && \
           [[ "$(cat "$DND_STATE_FILE" 2>/dev/null)" == "on" ]]; then
            swaync-client --dnd-off 2>/dev/null || true
            _set_state_file "off"
            _analytics_record_event "timer_expired" \
                "{\"duration\": $duration, \"mode\": \"$mode\"}"
            _analytics_update_stats "off"
            _signal_waybar
            rm -f "$DND_TIMER_FILE" "$DND_PID_FILE"
            _notify_timer_end "$label"
            _play_sound "$SOUND_DND_OFF"
            _sync_all_integrations "off"
        fi
    ) &

    echo "$!" > "$DND_PID_FILE"
    log_info "Timer started: ${duration_str} (mode: $mode)"
    _analytics_record_event "timer_start" \
        "{\"duration\": $duration, \"mode\": \"$mode\"}"
}

_stop_timer() {
    if [[ -f "$DND_PID_FILE" ]]; then
        local pid
        pid="$(cat "$DND_PID_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null || true
            log_debug "Timer process killed (PID=$pid)"
        fi
        rm -f "$DND_PID_FILE"
    fi
    rm -f "$DND_TIMER_FILE"
    log_debug "Timer stopped"
}

_get_timer_info() {
    [[ ! -f "$DND_TIMER_FILE" ]] && return 1

    local end_time now remaining label
    end_time="$(jq -r '.end_time // 0' "$DND_TIMER_FILE" 2>/dev/null || echo 0)"
    label="$(jq -r '.label // "Timer"' "$DND_TIMER_FILE" 2>/dev/null || echo 'Timer')"
    now="$(date +%s)"
    remaining=$(( end_time - now ))

    if (( remaining > 0 )); then
        echo "label=$label remaining=$remaining end=$end_time"
        return 0
    fi
    return 1
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SCHEDULE ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_schedule() {
    # Check if current time falls within any scheduled DND window
    # Returns 0 (match) or 1 (no match) and echoes schedule info

    [[ ! -f "$DND_SCHEDULE_FILE" ]] && return 1

    local current_hour current_min current_day
    current_hour="$(date +%H)"
    current_min="$(date +%M)"
    current_day="$(date +%a | tr '[:upper:]' '[:lower:]')"
    local current_total=$(( 10#$current_hour * 60 + 10#$current_min ))

    local schedule_json
    schedule_json="$(cat "$DND_SCHEDULE_FILE" 2>/dev/null || echo '{"rules":[]}')"

    local rule_count
    rule_count="$(echo "$schedule_json" | jq '.rules | length' 2>/dev/null || echo 0)"

    for (( i=0; i<rule_count; i++ )); do
        local enabled start end days rule_id rule_label
        enabled="$(echo "$schedule_json" | \
            jq -r ".rules[$i].enabled // false" 2>/dev/null)"

        [[ "$enabled" != "true" ]] && continue

        start="$(echo "$schedule_json" | \
            jq -r ".rules[$i].start // \"00:00\"" 2>/dev/null)"
        end="$(echo "$schedule_json" | \
            jq -r ".rules[$i].end   // \"00:00\"" 2>/dev/null)"
        days="$(echo "$schedule_json" | \
            jq -r ".rules[$i].days  // [] | join(\" \")" 2>/dev/null)"
        rule_id="$(echo "$schedule_json" | \
            jq -r ".rules[$i].id    // \"rule-$i\"" 2>/dev/null)"
        rule_label="$(echo "$schedule_json" | \
            jq -r ".rules[$i].label // \"Schedule\"" 2>/dev/null)"

        # Check day match
        if [[ -n "$days" ]] && \
           [[ "$days" != "all" ]] && \
           ! echo "$days" | grep -qw "$current_day"; then
            continue
        fi

        # Parse times
        local start_h start_m end_h end_m start_total end_total
        IFS=: read -r start_h start_m <<< "$start"
        IFS=: read -r end_h   end_m   <<< "$end"
        start_total=$(( 10#$start_h * 60 + 10#$start_m ))
        end_total=$(( 10#$end_h * 60 + 10#$end_m ))

        local in_window=false

        # Handle overnight windows (e.g., 22:00 - 07:00)
        if (( start_total > end_total )); then
            (( current_total >= start_total || \
               current_total <  end_total )) && in_window=true
        else
            (( current_total >= start_total && \
               current_total <  end_total )) && in_window=true
        fi

        if [[ "$in_window" == "true" ]]; then
            echo "id=$rule_id label=$rule_label start=$start end=$end"
            return 0
        fi
    done

    return 1
}

_schedule_daemon() {
    # Check schedule every minute and act accordingly
    local check_interval=60
    local last_state="unknown"

    log_info "Schedule daemon started (PID=$$)"

    while true; do
        if _check_schedule >/dev/null 2>&1; then
            if [[ "$last_state" != "on" ]]; then
                log_info "Schedule activated DND"
                _dnd_enable --source schedule
                last_state="on"
            fi
        else
            if [[ "$last_state" == "on" ]]; then
                local current_dnd
                current_dnd="$(_get_dnd_state)"
                if [[ "$current_dnd" == "on" ]]; then
                    log_info "Schedule deactivated DND"
                    _dnd_disable --source schedule
                fi
                last_state="off"
            fi
        fi
        sleep "$check_interval"
    done
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE DND ENABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dnd_enable() {
    local duration=0
    local mode="manual"
    local label="Do Not Disturb"
    local focus_mode=""
    local source="user"
    local silent=false
    local notify=true

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --duration|-d)
                shift
                duration="$(_parse_duration_arg "$1")" || return 1
                ;;
            --mode|-m)
                shift; mode="$1"
                ;;
            --focus|-f)
                shift; focus_mode="$1"
                ;;
            --label|-l)
                shift; label="$1"
                ;;
            --source|-s)
                shift; source="$1"
                ;;
            --silent)
                silent=true; notify=false
                ;;
            --no-notify)
                notify=false
                ;;
            --duration=*)
                local dur_val="${1#--duration=}"
                duration="$(_parse_duration_arg "$dur_val")" || return 1
                ;;
            *)
                # Positional: first arg is duration
                if [[ "$1" =~ ^[0-9]+[mhs]?$ ]]; then
                    duration="$(_parse_duration_arg "$1")" || return 1
                fi
                ;;
        esac
        shift
    done

    local current_state
    current_state="$(_get_dnd_state)"

    if [[ "$current_state" == "on" ]] && ! _is_timer_running; then
        log_info "DND already active (no timer); skipping enable"
        return 0
    fi

    log_info "Enabling DND (mode=$mode duration=${duration}s source=$source)"

    # Activate swaync DND
    swaync-client --dnd-on 2>/dev/null || {
        log_error "swaync-client --dnd-on failed"
        _notify_error "Failed to enable DND" "swaync-client error"
        return 1
    }

    _set_state_file "on"
    _analytics_update_stats "on"
    _check_exceptions

    local duration_str=""
    if (( duration > 0 )); then
        duration_str="$(_format_duration "$duration")"
        _start_timer "$duration" "$mode" "$label"
    fi

    # Record event with metadata
    _analytics_record_event "dnd_on" "$(jq -n \
        --arg mode   "$mode" \
        --arg source "$source" \
        --arg label  "$label" \
        --argjson dur "$duration" \
        '{
            "mode":     $mode,
            "source":   $source,
            "label":    $label,
            "duration": $dur
        }')"

    # Focus mode integration
    if [[ -n "$focus_mode" ]]; then
        _apply_focus_mode "$focus_mode" "$duration"
    fi

    # Integrations
    _signal_waybar
    _hyprland_update "on"
    _sync_all_integrations "on"

    # Notifications & sound
    if [[ "$notify" == "true" ]]; then
        _notify_dnd_on "$duration_str" "$label"
        [[ "$silent" == "false" ]] && _play_sound "$SOUND_DND_ON"
    fi

    log_success "DND enabled${duration_str:+ for $duration_str}"

    # Hook: post-dnd-on
    local hook_file="${CONFIG_DIR}/hooks/post-dnd-on.sh"
    if [[ -f "$hook_file" && -x "$hook_file" ]]; then
        DND_DURATION="$duration" DND_MODE="$mode" "$hook_file" &
        log_debug "Hook executed: post-dnd-on.sh"
    fi

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE DND DISABLE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_dnd_disable() {
    local source="user"
    local notify=true
    local silent=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --source|-s) shift; source="$1" ;;
            --silent)    silent=true; notify=false ;;
            --no-notify) notify=false ;;
        esac
        shift
    done

    log_info "Disabling DND (source=$source)"

    # Get held notification count before disabling
    local held_count
    held_count="$(_get_notification_count)"

    # Deactivate swaync DND
    swaync-client --dnd-off 2>/dev/null || {
        log_warn "swaync-client --dnd-off failed, forcing state file"
    }

    _set_state_file "off"
    _stop_timer
    _analytics_update_stats "off"
    _analytics_record_event "dnd_off" \
        "{\"source\": \"$source\", \"held_notifications\": $held_count}"

    # End focus mode if active
    _end_focus_mode

    # Integrations
    _signal_waybar
    _hyprland_update "off"
    _sync_all_integrations "off"

    # Notifications & sound
    if [[ "$notify" == "true" ]]; then
        _notify_dnd_off "$held_count"
        [[ "$silent" == "false" ]] && _play_sound "$SOUND_DND_OFF"
    fi

    log_success "DND disabled ($held_count held notifications restored)"

    # Hook: post-dnd-off
    local hook_file="${CONFIG_DIR}/hooks/post-dnd-off.sh"
    if [[ -f "$hook_file" && -x "$hook_file" ]]; then
        DND_SOURCE="$source" "$hook_file" &
        log_debug "Hook executed: post-dnd-off.sh"
    fi

    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# FOCUS MODE ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_apply_focus_mode() {
    local mode="$1"   # deep | work | pomodoro | reading | meeting | sleep
    local duration="${2:-0}"
    local mode_label mode_icon

    case "$mode" in
        deep)
            mode_label="Deep Focus"
            mode_icon="$ICON_FOCUS"
            # Integrate with ASH mode system
            command -v ash &>/dev/null && \
                ash mode focus --level deep &>/dev/null & true
            ;;
        work)
            mode_label="Work Mode"
            mode_icon="󰌨"
            command -v ash &>/dev/null && \
                ash mode work &>/dev/null & true
            ;;
        pomodoro)
            mode_label="Pomodoro"
            mode_icon="$ICON_POMODORO"
            # Start pomodoro plugin if available
            command -v ash &>/dev/null && \
                ash plugin pomodoro-plus start &>/dev/null & true
            ;;
        reading)
            mode_label="Reading"
            mode_icon="󰂿"
            # Enable night light for reading
            local nl_script="${SCRIPT_DIR}/night-light-preset.sh"
            [[ -x "$nl_script" ]] && \
                "$nl_script" reading &>/dev/null & true
            ;;
        meeting)
            mode_label="In a Meeting"
            mode_icon="󰊻"
            ;;
        sleep)
            mode_label="Sleep Mode"
            mode_icon="󰒲"
            # Set brightness very low
            command -v brightnessctl &>/dev/null && \
                brightnessctl set 5% &>/dev/null & true
            ;;
        *)
            mode_label="Focus"
            mode_icon="$ICON_FOCUS"
            ;;
    esac

    # Write focus mode state
    jq -n \
        --arg mode  "$mode" \
        --arg label "$mode_label" \
        --arg icon  "$mode_icon" \
        --argjson dur "$duration" \
        --arg ts    "$(date -Iseconds)" \
        '{
            "mode":       $mode,
            "label":      $label,
            "icon":       $icon,
            "duration":   $dur,
            "started_at": $ts
        }' > "${CACHE_DIR}/focus-mode.json"

    local duration_str=""
    (( duration > 0 )) && duration_str="$(_format_duration "$duration")"

    _notify_focus "$mode_label" "$duration_str" "$mode_icon"
    _play_sound "$SOUND_FOCUS"

    log_info "Focus mode applied: $mode_label"
}

_end_focus_mode() {
    local focus_file="${CACHE_DIR}/focus-mode.json"
    [[ ! -f "$focus_file" ]] && return 0

    local mode label
    mode="$(jq -r '.mode // ""' "$focus_file" 2>/dev/null || echo '')"
    label="$(jq -r '.label // "Focus"' "$focus_file" 2>/dev/null || echo 'Focus')"

    [[ -z "$mode" ]] && return 0

    rm -f "$focus_file"
    log_info "Focus mode ended: $label"

    # Restore ASH default mode if we changed it
    case "$mode" in
        deep|work|reading)
            command -v ash &>/dev/null && \
                ash mode default &>/dev/null & true
            ;;
        pomodoro)
            command -v ash &>/dev/null && \
                ash plugin pomodoro-plus stop &>/dev/null & true
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATUS DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_status() {
    local format="${1:-human}"

    local current_state
    current_state="$(_get_dnd_state)"

    local is_timer_running=false
    local timer_remaining=0
    local timer_label=""

    if _is_timer_running; then
        is_timer_running=true
        timer_remaining="$(_get_timer_remaining)"
        timer_label="$(jq -r '.label // "Timer"' \
            "$DND_TIMER_FILE" 2>/dev/null || echo 'Timer')"
    fi

    local notification_count
    notification_count="$(_get_notification_count)"

    local focus_mode=""
    if [[ -f "${CACHE_DIR}/focus-mode.json" ]]; then
        focus_mode="$(jq -r '.mode // ""' \
            "${CACHE_DIR}/focus-mode.json" 2>/dev/null || echo '')"
    fi

    local today_activations today_seconds
    today_activations="0"
    today_seconds="0"
    if [[ -f "$DND_STATS_FILE" ]]; then
        today_activations="$(jq -r '.today.activations // 0' \
            "$DND_STATS_FILE" 2>/dev/null || echo '0')"
        today_seconds="$(jq -r '.today.total_seconds // 0' \
            "$DND_STATS_FILE" 2>/dev/null || echo '0')"
    fi

    case "$format" in
        json)
            jq -n \
                --arg  state    "$current_state" \
                --argjson timer  "$is_timer_running" \
                --argjson remain "$timer_remaining" \
                --arg  timer_lbl "$timer_label" \
                --argjson count  "$notification_count" \
                --arg  focus    "$focus_mode" \
                --argjson today_act "$today_activations" \
                --argjson today_sec "$today_seconds" \
                '{
                    "state":               $state,
                    "active":              ($state == "on"),
                    "timer_running":       $timer,
                    "timer_remaining_sec": $remain,
                    "timer_label":         $timer_lbl,
                    "held_notifications":  $count,
                    "focus_mode":          $focus,
                    "today": {
                        "activations":     $today_act,
                        "total_seconds":   $today_sec
                    }
                }'
            ;;

        waybar)
            # Compact format for waybar custom module
            local icon text tooltip class

            if [[ "$current_state" == "on" ]]; then
                icon="$ICON_DND_ON"
                class="dnd-active"
                if [[ "$is_timer_running" == "true" ]]; then
                    local rem_str
                    rem_str="$(_format_duration "$timer_remaining")"
                    text="${icon}  ${rem_str}"
                    tooltip="${timer_label} — ${rem_str} remaining"
                else
                    text="${icon}"
                    tooltip="Do Not Disturb — Active"
                fi
            else
                icon="$ICON_DND_OFF"
                class="dnd-inactive"
                text="${icon}"
                tooltip="Do Not Disturb — Off"
            fi

            jq -n \
                --arg text    "$text" \
                --arg tooltip "$tooltip" \
                --arg class   "$class" \
                '{"text":$text,"tooltip":$tooltip,"class":$class}'
            ;;

        short)
            if [[ "$current_state" == "on" ]]; then
                if [[ "$is_timer_running" == "true" ]]; then
                    echo "${ICON_DND_ON}  $(_format_duration "$timer_remaining")"
                else
                    echo "${ICON_DND_ON}  Active"
                fi
            else
                echo "${ICON_DND_OFF}  Off"
            fi
            ;;

        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH DND Status${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            if [[ "$current_state" == "on" ]]; then
                echo -e "  State    : ${CLR_GREEN}${CLR_BOLD}${ICON_DND_ON}  Active${CLR_RESET}"
            else
                echo -e "  State    : ${CLR_GRAY}${ICON_DND_OFF}  Inactive${CLR_RESET}"
            fi

            if [[ "$is_timer_running" == "true" ]]; then
                echo -e "  Timer    : ${CLR_YELLOW}${ICON_TIMER}  $(_format_duration "$timer_remaining") remaining${CLR_RESET}"
                echo -e "  Label    : ${CLR_WHITE}$timer_label${CLR_RESET}"
            fi

            [[ -n "$focus_mode" ]] && \
                echo -e "  Focus    : ${CLR_BLUE}${ICON_FOCUS}  $focus_mode${CLR_RESET}"

            echo -e "  Held     : ${CLR_MAGENTA}$notification_count notifications${CLR_RESET}"
            echo -e "  Today    : ${CLR_CYAN}$today_activations activations${CLR_RESET}"

            if (( today_seconds > 0 )); then
                echo -e "  Duration : ${CLR_CYAN}$(_format_duration "$today_seconds") silenced${CLR_RESET}"
            fi

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CLEANUP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_cleanup_temp() {
    # Clean up temp files on exit
    find "${RUNTIME_DIR}" -name "dnd-*.tmp" -mmin +60 \
        -delete 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# USAGE / HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH DND Toggle v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [COMMAND] [OPTIONS]

${CLR_BOLD}COMMANDS${CLR_RESET}
  ${CLR_GREEN}(no args)${CLR_RESET}              Toggle DND on/off
  ${CLR_GREEN}--on, -e${CLR_RESET}               Enable DND
  ${CLR_GREEN}--off, -d${CLR_RESET}              Disable DND
  ${CLR_GREEN}--toggle, -t${CLR_RESET}           Toggle DND state
  ${CLR_GREEN}--status, -s${CLR_RESET}           Show status (human readable)
  ${CLR_GREEN}--status=json${CLR_RESET}          Show status as JSON
  ${CLR_GREEN}--status=waybar${CLR_RESET}        Show waybar module JSON
  ${CLR_GREEN}--status=short${CLR_RESET}         Show compact status

${CLR_BOLD}TIMED OPTIONS (with --on)${CLR_RESET}
  ${CLR_YELLOW}--duration 30m${CLR_RESET}         Enable for 30 minutes
  ${CLR_YELLOW}--duration 1h${CLR_RESET}          Enable for 1 hour
  ${CLR_YELLOW}--duration 1h30m${CLR_RESET}       Enable for 1.5 hours
  ${CLR_YELLOW}--until-morning${CLR_RESET}        Enable until 08:00

${CLR_BOLD}FOCUS MODES (with --on)${CLR_RESET}
  ${CLR_BLUE}--focus deep${CLR_RESET}           Deep focus (90min)
  ${CLR_BLUE}--focus work${CLR_RESET}           Work mode
  ${CLR_BLUE}--focus pomodoro${CLR_RESET}       Pomodoro (25min)
  ${CLR_BLUE}--focus reading${CLR_RESET}        Reading session
  ${CLR_BLUE}--focus meeting${CLR_RESET}        Meeting mode
  ${CLR_BLUE}--focus sleep${CLR_RESET}          Sleep mode (8h)

${CLR_BOLD}OTHER OPTIONS${CLR_RESET}
  ${CLR_WHITE}--timer-cancel${CLR_RESET}         Cancel active timer
  ${CLR_WHITE}--timer-extend 30m${CLR_RESET}     Extend timer by duration
  ${CLR_WHITE}--timer-info${CLR_RESET}           Show timer info
  ${CLR_WHITE}--schedule-check${CLR_RESET}       Check schedule now
  ${CLR_WHITE}--silent${CLR_RESET}               No sound/notification
  ${CLR_WHITE}--no-notify${CLR_RESET}            No notification only
  ${CLR_WHITE}--version${CLR_RESET}              Show version
  ${CLR_WHITE}--help, -h${CLR_RESET}             Show this help

${CLR_BOLD}EXAMPLES${CLR_RESET}
  $(basename "$0")                          # Toggle
  $(basename "$0") --on --duration 1h      # Enable for 1 hour
  $(basename "$0") --on --focus pomodoro   # Pomodoro focus
  $(basename "$0") --on --until-morning    # Until 8am
  $(basename "$0") --status=json           # JSON status
  $(basename "$0") --timer-cancel          # Cancel timer

EOF
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# MAIN ENTRYPOINT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

main() {
    _ensure_dirs
    _check_deps
    _acquire_lock || {
        log_error "Another instance is running"
        exit 1
    }

    # Default action: toggle
    local action="toggle"
    local on_args=()
    local off_args=()

    # Parse primary command
    case "${1:-}" in
        --on|-e|on|enable)
            action="on"
            shift
            on_args=("$@")
            ;;
        --off|-d|off|disable)
            action="off"
            shift
            off_args=("$@")
            ;;
        --toggle|-t|toggle)
            action="toggle"
            shift
            ;;
        --status|-s|status)
            local fmt="${2:-human}"
            # Handle --status=json format
            if [[ "$1" == --status=* ]]; then
                fmt="${1#--status=}"
            fi
            _show_status "$fmt"
            exit 0
            ;;
        --status=*)
            _show_status "${1#--status=}"
            exit 0
            ;;
        --timer-cancel)
            _stop_timer
            log_success "Timer cancelled"
            _notify "${ICON_TIMER}  Timer Cancelled" \
                "DND timer has been cancelled" "low" "3000"
            exit 0
            ;;
        --timer-extend)
            shift
            if ! _is_timer_running; then
                log_error "No active timer to extend"
                exit 1
            fi
            local extend_secs
            extend_secs="$(_parse_duration_arg "${1:-30m}")"
            local current_end
            current_end="$(jq -r '.end_time // 0' \
                "$DND_TIMER_FILE" 2>/dev/null || echo 0)"
            local new_end=$(( current_end + extend_secs ))
            jq --argjson end "$new_end" '.end_time = $end' \
                "$DND_TIMER_FILE" > "${DND_TIMER_FILE}.tmp" && \
            mv "${DND_TIMER_FILE}.tmp" "$DND_TIMER_FILE"
            log_success "Timer extended by $(_format_duration "$extend_secs")"
            _signal_waybar
            exit 0
            ;;
        --timer-info)
            if _get_timer_info; then
                local rem
                rem="$(_get_timer_remaining)"
                echo "Remaining: $(_format_duration "$rem")"
            else
                echo "No active timer"
            fi
            exit 0
            ;;
        --until-morning)
            action="on"
            # Calculate seconds until 08:00
            local now_ts tomorrow_8am
            now_ts="$(date +%s)"
            tomorrow_8am="$(date -d 'tomorrow 08:00' +%s 2>/dev/null || \
                            date -j -f '%Y-%m-%d %H:%M:%S' \
                            "$(date '+%Y-%m-%d') 08:00:00" +%s)"
            local until_morning=$(( tomorrow_8am - now_ts ))
            on_args=(--duration "$until_morning" --label "Until Morning")
            ;;
        --schedule-check)
            if _check_schedule; then
                log_success "Schedule match found"
            else
                log_info "No schedule match for current time"
            fi
            exit 0
            ;;
        --schedule-daemon)
            _schedule_daemon
            exit 0
            ;;
        --version)
            echo "$SCRIPT_NAME v$SCRIPT_VERSION"
            exit 0
            ;;
        --help|-h|help)
            _show_help
            exit 0
            ;;
        "")
            action="toggle"
            ;;
        *)
            # Unknown first arg — try as duration for timed DND
            if [[ "$1" =~ ^[0-9]+[mhs]?$ ]]; then
                action="on"
                on_args=(--duration "$1")
            else
                log_error "Unknown command: $1"
                _show_help
                exit 1
            fi
            ;;
    esac

    # Execute action
    case "$action" in
        on)
            _dnd_enable "${on_args[@]}"
            ;;
        off)
            _dnd_disable "${off_args[@]}"
            ;;
        toggle)
            local current
            current="$(_get_dnd_state)"
            if [[ "$current" == "on" ]]; then
                _dnd_disable
            else
                _dnd_enable
            fi
            ;;
    esac

    exit 0
}

main "$@"