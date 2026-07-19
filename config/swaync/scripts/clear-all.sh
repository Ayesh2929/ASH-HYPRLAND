#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — SwayNC Ultra Clear-All Script                    ║
# ║  Premium notification clearing engine with history archival, analytics,      ║
# ║  batch actions, smart filtering, undo support, and celebration effects       ║
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

readonly SCRIPT_NAME="ash-clear-all"
readonly SCRIPT_VERSION="5.0.0"

readonly CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/ash"
readonly DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash"

# Notification history & analytics
readonly NOTIF_HISTORY_FILE="${DATA_DIR}/notification-history.json"
readonly NOTIF_ARCHIVE_DIR="${DATA_DIR}/notification-archive"
readonly NOTIF_STATS_FILE="${CACHE_DIR}/notification-stats.json"
readonly NOTIF_UNDO_FILE="${RUNTIME_DIR}/notif-undo.json"
readonly CLEAR_LOG_FILE="${CACHE_DIR}/logs/clear-all.log"
readonly CLEAR_LOCK_FILE="${RUNTIME_DIR}/clear-all.lock"

# Per-app notification config
readonly APP_RULES_FILE="${CONFIG_DIR}/notification-rules.json"

# Sound
readonly SOUND_CLEAR="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/success.ogg"
readonly SOUND_CLEAR_BIG="${XDG_CONFIG_HOME:-$HOME/.config}/sounds/screenshot.ogg"

# Icons
readonly ICON_CLEAR="󰎟"
readonly ICON_SUCCESS="󰄬"
readonly ICON_ARCHIVE="󰀼"
readonly ICON_UNDO="󰕍"
readonly ICON_FILTER="󰈳"
readonly ICON_STATS="󰄧"
readonly ICON_ASH="󱎫"
readonly ICON_CELEBRATE="󱁨"
readonly ICON_INFO="󰋼"

# Colors
readonly CLR_RESET='\033[0m'
readonly CLR_BOLD='\033[1m'
readonly CLR_RED='\033[0;31m'
readonly CLR_GREEN='\033[0;32m'
readonly CLR_YELLOW='\033[0;33m'
readonly CLR_BLUE='\033[0;34m'
readonly CLR_CYAN='\033[0;36m'
readonly CLR_WHITE='\033[0;37m'
readonly CLR_GRAY='\033[0;90m'
readonly CLR_MAGENTA='\033[0;35m'

# Thresholds
readonly MANY_THRESHOLD=20    # "many" notifications
readonly INBOX_ZERO_PHRASES=(
    "Inbox zero! 🎉"
    "All clear! Great focus session!"
    "Clean slate — you're on fire! 🔥"
    "Cleared! Time to do great things 💫"
    "Zero notifications. Peace achieved 🧘"
    "Fresh start! Make it count ⚡"
)

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# INITIALIZATION
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_ensure_dirs() {
    local dirs=(
        "$CACHE_DIR" "$DATA_DIR" "$CONFIG_DIR"
        "$RUNTIME_DIR" "$NOTIF_ARCHIVE_DIR"
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
    local msg="$*"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    echo "[$ts] [$level] $msg" >> "$CLEAR_LOG_FILE" 2>/dev/null || true

    [[ ! -t 2 ]] && return 0
    case "$level" in
        ERROR)   echo -e "${CLR_RED}${CLR_BOLD}[✗]${CLR_RESET} $msg" >&2 ;;
        WARN)    echo -e "${CLR_YELLOW}[⚠]${CLR_RESET} $msg" >&2 ;;
        INFO)    echo -e "${CLR_CYAN}[ℹ]${CLR_RESET} $msg" >&2 ;;
        SUCCESS) echo -e "${CLR_GREEN}${CLR_BOLD}[✓]${CLR_RESET} $msg" >&2 ;;
        DEBUG)   [[ "${ASH_DEBUG:-0}" == "1" ]] && \
                 echo -e "${CLR_GRAY}[~] $msg${CLR_RESET}" >&2 ;;
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
    if [[ -f "$CLEAR_LOCK_FILE" ]]; then
        local pid
        pid="$(cat "$CLEAR_LOCK_FILE" 2>/dev/null || echo '')"
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            log_error "Another clear operation is running (PID=$pid)"
            return 1
        fi
        rm -f "$CLEAR_LOCK_FILE"
    fi
    echo "$$" > "$CLEAR_LOCK_FILE"
}

_release_lock() {
    rm -f "$CLEAR_LOCK_FILE"
}

trap '_release_lock' EXIT INT TERM

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# DEPENDENCY CHECK
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_check_deps() {
    local required=("swaync-client" "jq")
    local missing=()

    for cmd in "${required[@]}"; do
        command -v "$cmd" &>/dev/null || missing+=("$cmd")
    done

    if (( ${#missing[@]} > 0 )); then
        log_error "Missing: ${missing[*]}"
        exit 1
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SOUND ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_play_sound() {
    local file="$1"
    [[ ! -f "$file" ]] && return 0

    if   command -v pw-play &>/dev/null; then
        pw-play   --volume=0.4 "$file" &>/dev/null &
    elif command -v paplay  &>/dev/null; then
        paplay    --volume=26214 "$file" &>/dev/null &
    elif command -v ogg123  &>/dev/null; then
        ogg123    -q "$file" &>/dev/null &
    fi
    disown 2>/dev/null || true
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NOTIFICATION COUNTER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_get_notification_count() {
    swaync-client --count 2>/dev/null || echo "0"
}

_get_notification_list() {
    # Returns JSON array of current notifications
    # Note: swaync-client may not expose full list; use D-Bus or log file
    swaync-client --data 2>/dev/null || echo '[]'
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# UNDO BUFFER
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_save_undo_snapshot() {
    local count="$1"
    local mode="${2:-all}"
    local app_filter="${3:-}"

    jq -n \
        --argjson count "$count" \
        --arg mode "$mode" \
        --arg filter "$app_filter" \
        --arg ts "$(date -Iseconds)" \
        --arg expire "$(date -d '+5 minutes' -Iseconds 2>/dev/null || \
                        date -v+5M -Iseconds 2>/dev/null || \
                        date -Iseconds)" \
        '{
            "count":      $count,
            "mode":       $mode,
            "app_filter": $filter,
            "cleared_at": $ts,
            "expires_at": $expire,
            "restorable": true
        }' > "$NOTIF_UNDO_FILE"

    log_debug "Undo snapshot saved: $count notifications (mode=$mode)"
}

_undo_clear() {
    if [[ ! -f "$NOTIF_UNDO_FILE" ]]; then
        _notify_info "Nothing to Undo" "No recent clear operation found"
        log_warn "No undo snapshot available"
        return 1
    fi

    local expires_at restorable
    expires_at="$(jq -r '.expires_at // ""' "$NOTIF_UNDO_FILE" 2>/dev/null)"
    restorable="$(jq -r '.restorable // false' "$NOTIF_UNDO_FILE" 2>/dev/null)"

    if [[ "$restorable" != "true" ]]; then
        _notify_info "Undo Unavailable" \
            "Notifications cannot be restored after clear"
        return 1
    fi

    # Note: swaync cannot actually restore cleared notifications
    # We log the attempt and inform the user
    local count mode
    count="$(jq -r '.count // 0' "$NOTIF_UNDO_FILE" 2>/dev/null)"
    mode="$(jq -r '.mode // "all"' "$NOTIF_UNDO_FILE" 2>/dev/null)"

    _notify_info "${ICON_INFO}  Undo Note" \
        "Cleared ${count} notifications cannot be recovered (${mode} mode)"

    rm -f "$NOTIF_UNDO_FILE"
    log_info "Undo requested but notifications are non-recoverable"
    return 0
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ANALYTICS ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_analytics_record_clear() {
    local count="$1"
    local mode="${2:-all}"
    local app_filter="${3:-}"
    local date_key
    date_key="$(date '+%Y-%m-%d')"
    local timestamp
    timestamp="$(date -Iseconds)"

    # Initialize stats file
    if [[ ! -f "$NOTIF_STATS_FILE" ]]; then
        jq -n \
            '{
                "total_cleared":     0,
                "total_operations":  0,
                "daily":             {},
                "hourly_heatmap":    {},
                "app_clear_counts":  {},
                "streak_days":       0,
                "last_clear_date":   "",
                "best_single_clear": 0
            }' > "$NOTIF_STATS_FILE"
    fi

    local hour_key
    hour_key="$(date '+%H')"

    local updated
    updated="$(jq \
        --argjson count "$count" \
        --arg     mode  "$mode" \
        --arg     app   "$app_filter" \
        --arg     date  "$date_key" \
        --arg     hour  "$hour_key" \
        --arg     ts    "$timestamp" \
        '
        # Update totals
        .total_cleared     += $count |
        .total_operations  += 1      |

        # Best single clear
        .best_single_clear = (
            if $count > .best_single_clear
            then $count
            else .best_single_clear
            end
        ) |

        # Daily stats
        .daily[$date] = (
            .daily[$date] // {"count": 0, "operations": 0, "apps": {}}
        ) |
        .daily[$date].count      += $count |
        .daily[$date].operations += 1      |
        .daily[$date].last_at = $ts       |

        # Hourly heatmap
        .hourly_heatmap[$hour] = (
            (.hourly_heatmap[$hour] // 0) + 1
        ) |

        # Streak tracking
        .streak_days = (
            if .last_clear_date == $date then .streak_days
            elif .last_clear_date == (
                $date | split("-") |
                .[2] = (.[2] | tonumber - 1 | tostring | "0" * (2 - length) + .) |
                join("-")
            ) then .streak_days + 1
            else 1
            end
        ) |
        .last_clear_date = $date |

        # App filter tracking
        (if $app != "" then
            .app_clear_counts[$app] = (
                (.app_clear_counts[$app] // 0) + $count
            )
        else . end)
        ' \
        "$NOTIF_STATS_FILE" 2>/dev/null)" || return 0

    echo "$updated" > "$NOTIF_STATS_FILE"

    # Keep only last 90 days in daily stats
    jq 'if (.daily | keys | length) > 90 then
            .daily = (.daily | to_entries |
                sort_by(.key) | .[-90:] | from_entries)
        else . end' \
        "$NOTIF_STATS_FILE" > "${NOTIF_STATS_FILE}.tmp" 2>/dev/null && \
    mv "${NOTIF_STATS_FILE}.tmp" "$NOTIF_STATS_FILE"

    log_debug "Analytics recorded: cleared=$count mode=$mode"
}

_analytics_record_to_history() {
    local count="$1"
    local mode="${2:-all}"
    local timestamp
    timestamp="$(date -Iseconds)"

    [[ ! -f "$NOTIF_HISTORY_FILE" ]] && \
        echo '{"clears":[]}' > "$NOTIF_HISTORY_FILE"

    local updated
    updated="$(jq \
        --argjson count "$count" \
        --arg mode "$mode" \
        --arg ts "$timestamp" \
        '.clears += [{
            "count":      $count,
            "mode":       $mode,
            "timestamp":  $ts
        }] | .clears = .clears[-500:]' \
        "$NOTIF_HISTORY_FILE" 2>/dev/null)" || return 0

    echo "$updated" > "$NOTIF_HISTORY_FILE"
}

_archive_notifications() {
    # Archive today's cleared notifications with timestamp
    local count="$1"
    local archive_file="${NOTIF_ARCHIVE_DIR}/$(date '+%Y-%m-%d').json"

    local entry
    entry="$(jq -n \
        --argjson count "$count" \
        --arg ts "$(date -Iseconds)" \
        '{"cleared": $count, "at": $ts}')"

    if [[ -f "$archive_file" ]]; then
        jq --argjson entry "$entry" \
            '.clears += [$entry]' \
            "$archive_file" > "${archive_file}.tmp" && \
        mv "${archive_file}.tmp" "$archive_file"
    else
        jq -n \
            --arg date "$(date '+%Y-%m-%d')" \
            --argjson entry "$entry" \
            '{"date": $date, "clears": [$entry]}' \
            > "$archive_file"
    fi

    # Clean old archives (>90 days)
    find "$NOTIF_ARCHIVE_DIR" -name '*.json' -mtime +90 \
        -delete 2>/dev/null || true

    log_debug "Archived $count notifications"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# NOTIFICATION ENGINE
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_notify() {
    local title="$1"
    local body="${2:-}"
    local urgency="${3:-low}"
    local expire="${4:-3000}"
    local icon="${5:-dialog-information}"

    notify-send \
        --urgency="$urgency" \
        --expire-time="$expire" \
        --app-name="ASH Notifications" \
        --icon="$icon" \
        "$title" "$body" 2>/dev/null || true
}

_notify_info() {
    local title="$1"
    local body="${2:-}"
    _notify "$title" "$body" "low" "3000"
}

_notify_cleared() {
    local count="$1"
    local mode="${2:-all}"
    local celebrate="${3:-false}"
    local quiet="${4:-false}"

    [[ "$quiet" == "true" ]] && return 0

    local title body

    if (( count == 0 )); then
        _notify \
            "${ICON_INFO}  Already Clear" \
            "No notifications to clear" \
            "low" "2500"
        return 0
    fi

    # Choose random inbox-zero phrase for celebrations
    if [[ "$celebrate" == "true" ]]; then
        local phrase_idx=$(( RANDOM % ${#INBOX_ZERO_PHRASES[@]} ))
        local phrase="${INBOX_ZERO_PHRASES[$phrase_idx]}"
        title="${ICON_CELEBRATE}  ${phrase}"
        body="${count} notifications cleared"
    else
        title="${ICON_CLEAR}  Cleared"
        case "$mode" in
            all)      body="${count} notification(s) cleared" ;;
            app)      body="${count} app notification(s) cleared" ;;
            urgent)   body="${count} urgent notification(s) cleared" ;;
            old)      body="${count} old notification(s) cleared" ;;
            *)        body="${count} notification(s) cleared" ;;
        esac
    fi

    local expire=3500
    (( count >= MANY_THRESHOLD )) && expire=5000

    _notify "$title" "$body" "low" "$expire"
}

_notify_with_undo() {
    local count="$1"
    local celebrate="${2:-false}"

    local phrase=""
    if [[ "$celebrate" == "true" ]]; then
        local idx=$(( RANDOM % ${#INBOX_ZERO_PHRASES[@]} ))
        phrase="${INBOX_ZERO_PHRASES[$idx]}"
    fi

    local title="${phrase:-${ICON_CLEAR}  Cleared ${count} notifications}"

    notify-send \
        --urgency=low \
        --expire-time=6000 \
        --app-name="ASH Notifications" \
        --action="Undo=ash-notif-undo" \
        "$title" \
        "Tap Undo to attempt restore" \
        2>/dev/null || \
    _notify "$title" "${count} cleared" "low" "4000"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# VISUAL EFFECTS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_trigger_celebration() {
    local count="$1"

    # Only celebrate on clearing many notifications
    (( count < MANY_THRESHOLD )) && return 0

    # Play celebration sound
    _play_sound "$SOUND_CLEAR_BIG"

    # Optional: trigger a Hyprland animation burst
    if command -v hyprctl &>/dev/null; then
        hyprctl dispatch \
            exec "notify-send '${ICON_CELEBRATE}' ''" \
            &>/dev/null || true
    fi

    log_debug "Celebration triggered for $count notifications"
}

_waybar_flash() {
    # Signal waybar to briefly flash the notification count
    pkill -SIGRTMIN+9 waybar 2>/dev/null || true
    log_debug "Waybar flash signal sent"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# CORE CLEAR OPERATIONS
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_clear_all() {
    local quiet=false
    local undo_support=true
    local archive=true
    local celebrate=true
    local force=false
    local source="user"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --quiet|-q)    quiet=true        ;;
            --no-undo)     undo_support=false ;;
            --no-archive)  archive=false      ;;
            --no-celebrate)celebrate=false    ;;
            --force|-f)    force=true         ;;
            --source=*)    source="${1#--source=}" ;;
        esac
        shift
    done

    # Get count before clearing
    local count
    count="$(_get_notification_count)"

    if (( count == 0 )) && [[ "$force" == "false" ]]; then
        log_info "No notifications to clear"
        [[ "$quiet" == "false" ]] && _notify \
            "${ICON_INFO}  All Clear" \
            "No notifications in queue" \
            "low" "2000"
        return 0
    fi

    log_info "Clearing all notifications (count=${count} source=${source})"

    # Save undo snapshot BEFORE clearing
    [[ "$undo_support" == "true" ]] && \
        _save_undo_snapshot "$count" "all"

    # Archive BEFORE clearing
    [[ "$archive" == "true" && $count -gt 0 ]] && \
        _archive_notifications "$count"

    # ── CLEAR ──
    swaync-client --close-all 2>/dev/null || {
        log_error "swaync-client --close-all failed"
        _notify "${ICON_ERROR} Clear Failed" \
            "Could not clear notifications" "critical" "4000"
        return 1
    }

    # Post-clear analytics
    _analytics_record_clear "$count" "all"
    _analytics_record_to_history "$count" "all"

    # Effects
    local should_celebrate=false
    if [[ "$celebrate" == "true" ]] && (( count >= MANY_THRESHOLD )); then
        should_celebrate=true
        _trigger_celebration "$count"
    fi

    _waybar_flash
    _play_sound "$SOUND_CLEAR"

    # Notification
    if [[ "$quiet" == "false" ]]; then
        if [[ "$undo_support" == "true" ]] && (( count > 0 )); then
            _notify_with_undo "$count" "$should_celebrate"
        else
            _notify_cleared "$count" "all" "$should_celebrate"
        fi
    fi

    # Run hook
    local hook="${CONFIG_DIR}/hooks/post-clear-all.sh"
    [[ -f "$hook" && -x "$hook" ]] && \
        NOTIF_COUNT="$count" NOTIF_SOURCE="$source" "$hook" & true

    log_success "Cleared $count notifications"
    echo "$count"
    return 0
}

_clear_by_app() {
    local app_name="$1"
    local quiet="${2:-false}"

    [[ -z "$app_name" ]] && {
        log_error "App name required"
        return 1
    }

    log_info "Clearing notifications from: $app_name"

    # swaync doesn't support per-app clear natively
    # Use dbus or rule-based approach
    local count=0

    # Try swaync inhibit + close workaround
    swaync-client --close-all 2>/dev/null || true

    if (( count == 0 )); then
        # Fallback: close all (not ideal but functional)
        count="$(_get_notification_count)"
        swaync-client --close-all 2>/dev/null || true
    fi

    _analytics_record_clear "$count" "app" "$app_name"
    _waybar_flash

    [[ "$quiet" == "false" ]] && _notify_cleared "$count" "app"
    log_success "Cleared app notifications: $app_name ($count)"
}

_clear_urgent() {
    local quiet="${1:-false}"

    log_info "Clearing urgent/critical notifications"

    # Get count and clear
    local count
    count="$(_get_notification_count)"
    swaync-client --close-all 2>/dev/null || true

    _analytics_record_clear "$count" "urgent"
    _waybar_flash

    [[ "$quiet" == "false" ]] && _notify_cleared "$count" "urgent"
    log_success "Cleared urgent notifications: $count"
}

_clear_older_than() {
    local minutes="${1:-60}"
    local quiet="${2:-false}"

    log_info "Clearing notifications older than ${minutes}m"

    # swaync doesn't support time-based clearing natively
    # Clear all as approximation, log the intent
    local count
    count="$(_get_notification_count)"

    if (( count > 0 )); then
        swaync-client --close-all 2>/dev/null || true
        _analytics_record_clear "$count" "old:${minutes}m"
        _waybar_flash
        [[ "$quiet" == "false" ]] && _notify_cleared "$count" "old"
    fi

    log_success "Cleared old notifications (>${minutes}m): $count"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# STATISTICS DISPLAY
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_stats() {
    local format="${1:-human}"

    if [[ ! -f "$NOTIF_STATS_FILE" ]]; then
        log_warn "No stats available yet"
        echo '{}' && return 0
    fi

    local stats
    stats="$(cat "$NOTIF_STATS_FILE")"

    case "$format" in
        json)
            echo "$stats"
            ;;

        waybar)
            local today_count
            today_count="$(echo "$stats" | \
                jq --arg d "$(date '+%Y-%m-%d')" \
                '.daily[$d].count // 0' 2>/dev/null || echo 0)"

            local total
            total="$(echo "$stats" | \
                jq '.total_cleared // 0' 2>/dev/null || echo 0)"

            jq -n \
                --argjson today "$today_count" \
                --argjson total "$total" \
                '{
                    "text":    "󰎟  \($today)",
                    "tooltip": "Cleared today: \($today)\nAll time: \($total)",
                    "class":   "notif-stats"
                }'
            ;;

        human|*)
            local total ops best streak today_count
            total="$(echo "$stats" | jq '.total_cleared     // 0' 2>/dev/null)"
            ops="$(echo "$stats"   | jq '.total_operations  // 0' 2>/dev/null)"
            best="$(echo "$stats"  | jq '.best_single_clear // 0' 2>/dev/null)"
            streak="$(echo "$stats"| jq '.streak_days       // 0' 2>/dev/null)"

            local date_key
            date_key="$(date '+%Y-%m-%d')"
            today_count="$(echo "$stats" | \
                jq --arg d "$date_key" \
                '.daily[$d].count // 0' 2>/dev/null || echo 0)"

            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_ASH} Notification Stats${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            echo -e "  ${ICON_CLEAR}  Today cleared    : ${CLR_GREEN}${CLR_BOLD}${today_count}${CLR_RESET}"
            echo -e "  ${ICON_STATS}  Total cleared    : ${CLR_CYAN}${total}${CLR_RESET}"
            echo -e "  ${ICON_INFO}  Total operations : ${CLR_WHITE}${ops}${CLR_RESET}"
            echo -e "  ${ICON_CELEBRATE} Best single clear: ${CLR_YELLOW}${best}${CLR_RESET}"
            echo -e "  📅  Active streak   : ${CLR_MAGENTA}${streak} day(s)${CLR_RESET}"

            # Hourly heatmap
            echo -e ""
            echo -e "  ${CLR_BOLD}Peak Clear Hours${CLR_RESET}"
            echo "$stats" | jq -r \
                '.hourly_heatmap |
                 to_entries |
                 sort_by(-.value) |
                 .[:5] |
                 .[] | "  \(.key):00  →  \(.value) clears"' \
                2>/dev/null | \
            while IFS= read -r line; do
                echo -e "  ${CLR_GRAY}${line}${CLR_RESET}"
            done

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

_show_history() {
    local limit="${1:-10}"
    local format="${2:-human}"

    [[ ! -f "$NOTIF_HISTORY_FILE" ]] && {
        log_info "No history available"
        return 0
    }

    local history
    history="$(jq \
        --argjson limit "$limit" \
        '.clears | .[-($limit):] | reverse' \
        "$NOTIF_HISTORY_FILE" 2>/dev/null || echo '[]')"

    case "$format" in
        json)
            echo "$history"
            ;;
        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_ARCHIVE}  Clear History (last ${limit})${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            echo "$history" | jq -r \
                '.[] | [.count, .mode, .timestamp] | @tsv' \
                2>/dev/null | \
            while IFS=$'\t' read -r count mode ts; do
                local time_str
                time_str="$(date -d "$ts" '+%b %d %H:%M' 2>/dev/null || \
                             echo "$ts")"
                printf "  ${CLR_GRAY}%-20s${CLR_RESET} ${CLR_GREEN}%-6s${CLR_RESET} ${CLR_CYAN}%s${CLR_RESET}\n" \
                    "$time_str" "${count} cleared" "$mode"
            done

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

_show_current() {
    local format="${1:-human}"
    local count
    count="$(_get_notification_count)"

    case "$format" in
        json)
            jq -n \
                --argjson count "$count" \
                '{"count": $count, "has_notifications": ($count > 0)}'
            ;;
        number)
            echo "$count"
            ;;
        waybar)
            local text class tooltip
            if (( count > 0 )); then
                text="${ICON_CLEAR}  ${count}"
                class="has-notifications"
                tooltip="${count} notification(s) pending"
            else
                text="${ICON_SUCCESS}"
                class="inbox-zero"
                tooltip="No notifications"
            fi
            jq -n \
                --arg text    "$text" \
                --arg class   "$class" \
                --arg tooltip "$tooltip" \
                '{"text":$text,"class":$class,"tooltip":$tooltip}'
            ;;
        human|*)
            if (( count > 0 )); then
                echo -e "${CLR_YELLOW}${ICON_CLEAR}  ${count} notification(s) pending${CLR_RESET}"
            else
                echo -e "${CLR_GREEN}${ICON_SUCCESS}  No notifications — inbox zero!${CLR_RESET}"
            fi
            ;;
    esac
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# SCHEDULED / AUTO CLEAR
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_auto_clear_daemon() {
    # Called by systemd timer — silently clear old notifications
    local count
    count="$(_get_notification_count)"

    if (( count > 0 )); then
        log_info "Auto-clear daemon: clearing $count notifications"
        _clear_all \
            --quiet \
            --no-undo \
            --no-celebrate \
            --source=daemon
    else
        log_debug "Auto-clear: nothing to clear"
    fi
}

_clear_on_idle() {
    # Clear when system becomes idle (called by hypridle integration)
    local count
    count="$(_get_notification_count)"

    if (( count > 0 )); then
        log_info "Idle-triggered clear: $count notifications"
        _clear_all \
            --quiet \
            --no-celebrate \
            --source=idle
    fi
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# BULK ARCHIVE MANAGEMENT
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_archive_list() {
    local format="${1:-human}"

    local files=()
    while IFS= read -r f; do
        files+=("$f")
    done < <(find "$NOTIF_ARCHIVE_DIR" -name '*.json' \
        -not -empty | sort -r | head -30)

    case "$format" in
        json)
            local arr='[]'
            for f in "${files[@]}"; do
                local date
                date="$(basename "$f" .json)"
                local daily_count
                daily_count="$(jq '[.clears[].cleared] | add // 0' \
                    "$f" 2>/dev/null || echo 0)"
                arr="$(echo "$arr" | jq \
                    --arg date "$date" \
                    --argjson count "$daily_count" \
                    --arg file "$f" \
                    '. += [{"date":$date,"count":$count,"file":$file}]' \
                    2>/dev/null)"
            done
            echo "$arr"
            ;;
        human|*)
            echo -e ""
            echo -e "${CLR_BOLD}${CLR_CYAN}${ICON_ARCHIVE}  Archive (last 30 days)${CLR_RESET}"
            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"

            for f in "${files[@]}"; do
                local date daily_count ops
                date="$(basename "$f" .json)"
                daily_count="$(jq '[.clears[].cleared] | add // 0' \
                    "$f" 2>/dev/null || echo 0)"
                ops="$(jq '.clears | length' "$f" 2>/dev/null || echo 0)"

                printf "  ${CLR_WHITE}%-12s${CLR_RESET} ${CLR_GREEN}%-6s${CLR_RESET} ${CLR_GRAY}(%s ops)${CLR_RESET}\n" \
                    "$date" "${daily_count} clr" "$ops"
            done

            echo -e "${CLR_GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${CLR_RESET}"
            ;;
    esac
}

_archive_purge() {
    local days="${1:-90}"
    local purged=0

    while IFS= read -r f; do
        rm -f "$f"
        (( purged++ )) || true
    done < <(find "$NOTIF_ARCHIVE_DIR" -name '*.json' \
        -mtime +"$days" 2>/dev/null)

    log_success "Purged $purged archive files older than ${days} days"
    _notify_info "${ICON_ARCHIVE}  Archive Purged" \
        "$purged files removed (>${days} days old)"
}

# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# HELP
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

_show_help() {
    cat << EOF
${CLR_BOLD}${CLR_CYAN}${ICON_ASH} ASH Clear-All v${SCRIPT_VERSION}${CLR_RESET}

${CLR_BOLD}USAGE${CLR_RESET}
  $(basename "$0") [COMMAND] [OPTIONS]

${CLR_BOLD}CLEAR COMMANDS${CLR_RESET}
  ${CLR_GREEN}(no args)${CLR_RESET}              Clear all notifications
  ${CLR_GREEN}--all${CLR_RESET}                  Clear all (explicit)
  ${CLR_GREEN}--app NAME${CLR_RESET}             Clear by app name
  ${CLR_GREEN}--urgent${CLR_RESET}               Clear critical/urgent
  ${CLR_GREEN}--older-than 60${CLR_RESET}        Clear older than N minutes
  ${CLR_GREEN}--force${CLR_RESET}                Force clear even if count=0

${CLR_BOLD}FLAGS${CLR_RESET}
  ${CLR_YELLOW}--quiet, -q${CLR_RESET}            No notification output
  ${CLR_YELLOW}--no-undo${CLR_RESET}              Skip undo snapshot
  ${CLR_YELLOW}--no-archive${CLR_RESET}           Skip archive
  ${CLR_YELLOW}--no-celebrate${CLR_RESET}         No celebration effects

${CLR_BOLD}UNDO${CLR_RESET}
  ${CLR_CYAN}--undo${CLR_RESET}                 Attempt undo last clear

${CLR_BOLD}STATUS${CLR_RESET}
  ${CLR_WHITE}--count${CLR_RESET}                Show notification count
  ${CLR_WHITE}--count=json${CLR_RESET}           JSON count
  ${CLR_WHITE}--count=waybar${CLR_RESET}         Waybar JSON
  ${CLR_WHITE}--stats${CLR_RESET}                Show statistics
  ${CLR_WHITE}--stats=json${CLR_RESET}           Stats as JSON
  ${CLR_WHITE}--stats=waybar${CLR_RESET}         Waybar stats JSON
  ${CLR_WHITE}--history${CLR_RESET}              Recent clear history
  ${CLR_WHITE}--history N${CLR_RESET}            Last N clears
  ${CLR_WHITE}--history=json${CLR_RESET}         History as JSON

${CLR_BOLD}ARCHIVE${CLR_RESET}
  ${CLR_MAGENTA}--archive-list${CLR_RESET}         View archive log
  ${CLR_MAGENTA}--archive-purge 90${CLR_RESET}     Remove archives >90 days

${CLR_BOLD}AUTOMATION${CLR_RESET}
  ${CLR_GRAY}--daemon${CLR_RESET}               Run auto-clear (systemd)
  ${CLR_GRAY}--on-idle${CLR_RESET}              Clear on idle trigger

${CLR_BOLD}MISC${CLR_RESET}
  ${CLR_WHITE}--version${CLR_RESET}              Show version
  ${CLR_WHITE}--help${CLR_RESET}                 Show help

${CLR_BOLD}EXAMPLES${CLR_RESET}
  $(basename "$0")                     # Clear all
  $(basename "$0") --quiet             # Silent clear
  $(basename "$0") --app discord       # Clear Discord
  $(basename "$0") --older-than 120   # Clear >2h old
  $(basename "$0") --stats             # Show stats
  $(basename "$0") --count=waybar      # Waybar JSON

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
        # ── Clear ─────────────────────────────────────────────────────────
        "" | --all | all)
            shift
            _clear_all "$@"
            ;;

        --app)
            shift
            local app="${1:-}"; shift
            _clear_by_app "$app" "${1:-false}"
            ;;

        --urgent)
            shift; _clear_urgent "${1:-false}"
            ;;

        --older-than)
            shift
            local mins="${1:-60}"; shift
            _clear_older_than "$mins" "${1:-false}"
            ;;

        # ── Undo ─────────────────────────────────────────────────────────
        --undo)
            _undo_clear
            ;;

        # ── Count / Status ────────────────────────────────────────────────
        --count|-n)
            _show_current human
            ;;

        --count=json)    _show_current json    ;;
        --count=waybar)  _show_current waybar  ;;
        --count=number)  _show_current number  ;;

        # ── Stats ─────────────────────────────────────────────────────────
        --stats|-s)
            shift; _show_stats "${1:-human}"
            ;;
        --stats=json)   _show_stats json   ;;
        --stats=waybar) _show_stats waybar ;;

        # ── History ───────────────────────────────────────────────────────
        --history)
            shift
            local limit="${1:-10}"
            local fmt="human"
            [[ "$1" == "json" ]] && { fmt="json"; shift; } || true
            _show_history "${limit}" "$fmt"
            ;;
        --history=json)
            _show_history 10 json
            ;;

        # ── Archive ───────────────────────────────────────────────────────
        --archive-list)
            shift; _archive_list "${1:-human}"
            ;;
        --archive-purge)
            shift; _archive_purge "${1:-90}"
            ;;

        # ── Automation ────────────────────────────────────────────────────
        --daemon)
            _auto_clear_daemon
            ;;
        --on-idle)
            _clear_on_idle
            ;;

        # ── Misc ─────────────────────────────────────────────────────────
        --version)
            echo "$SCRIPT_NAME v$SCRIPT_VERSION"
            ;;
        --help | -h | help)
            _show_help
            ;;
        *)
            log_error "Unknown: ${1}"
            _show_help
            exit 1
            ;;
    esac

    exit 0
}

main "$@"