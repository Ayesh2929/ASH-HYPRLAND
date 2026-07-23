#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  📝 ASH DOTFILES v5.0 OMEGA — DUNST NOTIFICATION LOGGER                    ║
# ║  Structured JSON logging • Analytics • History • Search • Export           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 📁 Location  : ~/.config/dunst/scripts/dunst-logger.sh
# 📦 Requires  : bash ≥ 5.0, jq, dunst
# 🔗 Called by : dunstrc → script = dunst-logger.sh (global_script_on_close)
# 🎯 Purpose   : Logs ALL dunst notifications to structured JSON
#                Enables history, analytics, search, and export
#
# Log Format (JSONL — one JSON object per line):
# {
#   "timestamp": "2024-01-15T14:30:00Z",
#   "unix_time": 1705327800,
#   "id": 42,
#   "app": "spotify",
#   "urgency": "low",
#   "summary": "Now Playing",
#   "body": "Artist — Song Title",
#   "icon": "/path/to/icon.png",
#   "timeout": 4000,
#   "progress": -1,
#   "urls": [],
#   "stack_tag": "",
#   "action_taken": false,
#   "session_id": "abc123"
# }
#
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────────────────────────────────
# 📁  PATHS & CONSTANTS
# ──────────────────────────────────────────────────────────────────────────────

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly ASH_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly LOG_DIR="${ASH_DATA}/logs"
readonly HISTORY_DIR="${ASH_DATA}/history/notifications"
readonly ANALYTICS_DIR="${ASH_DATA}/analytics"
readonly CACHE_DIR="${ASH_DATA}/cache/notifications"

# Log files
readonly NOTIF_LOG="${LOG_DIR}/notifications.jsonl"
readonly DAILY_LOG="${LOG_DIR}/notifications-$(date +%Y-%m-%d).jsonl"
readonly STATS_FILE="${ANALYTICS_DIR}/notification-stats.json"
readonly SESSION_FILE="${CACHE_DIR}/session.json"
readonly SEARCH_INDEX="${CACHE_DIR}/search-index.tsv"

# Archive settings
readonly MAX_LOG_SIZE_MB=50
readonly MAX_HISTORY_DAYS=90
readonly MAX_SESSION_NOTIFICATIONS=1000

# Dunst environment (with safe defaults)
readonly APP="${DUNST_APP_NAME:-unknown}"
readonly SUMMARY="${DUNST_SUMMARY:-}"
readonly BODY="${DUNST_BODY:-}"
readonly ICON="${DUNST_ICON_PATH:-}"
readonly URGENCY="${DUNST_URGENCY:-NORMAL}"
readonly NOTIF_ID="${DUNST_ID:-0}"
readonly PROGRESS="${DUNST_PROGRESS:--1}"
readonly TIMEOUT="${DUNST_TIMEOUT:-5000}"
readonly TIMESTAMP_UNIX="${DUNST_TIMESTAMP:-$(date +%s)}"
readonly STACK_TAG="${DUNST_STACK_TAG:-}"
readonly URLS="${DUNST_URLS:-}"

# ──────────────────────────────────────────────────────────────────────────────
# 🧰  UTILITY FUNCTIONS
# ──────────────────────────────────────────────────────────────────────────────

_ensure_dirs() {
    mkdir -p \
        "${LOG_DIR}" \
        "${HISTORY_DIR}" \
        "${ANALYTICS_DIR}" \
        "${CACHE_DIR}" \
        2>/dev/null || true
}

_iso_timestamp() {
    date -d "@${TIMESTAMP_UNIX}" '+%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
    date '+%Y-%m-%dT%H:%M:%SZ'
}

_today() {
    date '+%Y-%m-%d'
}

_hour() {
    date '+%H'
}

_weekday() {
    date '+%A'
}

_get_session_id() {
    local session_file="${CACHE_DIR}/.session_id"
    if [[ ! -f "${session_file}" ]]; then
        # Generate session ID based on login time
        local session_id
        session_id="$(loginctl show-session --property=Id --value 2>/dev/null || \
                      cat /proc/sys/kernel/random/uuid 2>/dev/null | \
                      cut -c1-8)"
        printf '%s' "${session_id:-unknown}" > "${session_file}"
    fi
    cat "${session_file}"
}

_json_escape() {
    local str="${1:-}"
    # Escape for JSON: backslashes, quotes, control chars
    printf '%s' "${str}" | \
        sed 's/\\/\\\\/g; s/"/\\"/g; s/\t/\\t/g; s/\r/\\r/g' | \
        tr -d '\000-\031' | \
        head -c 2048  # max 2KB per field
}

_is_suppressed() {
    # Skip logging certain noisy apps/events
    local app_lower="${APP,,}"
    local summary_lower="${SUMMARY,,}"

    local suppressed_apps=(
        "dbus-daemon"
        "xdg-desktop-portal"
        "at-spi"
        "gvfs"
        "colord"
    )

    for suppressed in "${suppressed_apps[@]}"; do
        if [[ "${app_lower}" == "${suppressed}" ]]; then
            return 0
        fi
    done

    # Skip typing indicators
    if [[ "${summary_lower}" == *"is typing"* ]]; then
        return 0
    fi

    # Skip heartbeat/polling
    if [[ "${summary_lower}" == *"heartbeat"* ]] || \
       [[ "${summary_lower}" == *"polling"* ]]; then
        return 0
    fi

    return 1
}

# ──────────────────────────────────────────────────────────────────────────────
# 📊  JSON LOG ENTRY BUILDER
# ──────────────────────────────────────────────────────────────────────────────

_build_json_entry() {
    local iso_ts
    iso_ts="$(_iso_timestamp)"

    local session_id
    session_id="$(_get_session_id)"

    local app_escaped
    app_escaped="$(_json_escape "${APP}")"

    local summary_escaped
    summary_escaped="$(_json_escape "${SUMMARY}")"

    local body_escaped
    body_escaped="$(_json_escape "${BODY}")"

    local icon_escaped
    icon_escaped="$(_json_escape "${ICON}")"

    local stack_tag_escaped
    stack_tag_escaped="$(_json_escape "${STACK_TAG}")"

    local urgency_lower="${URGENCY,,}"

    # Build URL array
    local urls_json="[]"
    if [[ -n "${URLS}" ]]; then
        urls_json="[$(printf '%s' "${URLS}" | \
            tr ' ' '\n' | \
            grep -E '^https?://' | \
            while IFS= read -r url; do
                printf '"%s",' "$(_json_escape "${url}")"
            done | sed 's/,$//')]"
    fi

    # Determine category
    local category
    category="$(_categorize_app "${APP}")"

    # Build complete JSON entry
    cat <<JSON
{"timestamp":"${iso_ts}","unix_time":${TIMESTAMP_UNIX},"id":${NOTIF_ID},"session":"${session_id}","app":"${app_escaped}","category":"${category}","urgency":"${urgency_lower}","summary":"${summary_escaped}","body":"${body_escaped}","icon":"${icon_escaped}","timeout":${TIMEOUT},"progress":${PROGRESS},"stack_tag":"${stack_tag_escaped}","urls":${urls_json},"date":"$(_today)","hour":$(_hour),"weekday":"$(_weekday)"}
JSON
}

_categorize_app() {
    local app="${1,,}"
    case "${app}" in
        spotify|playerctl|mpd|ncmpcpp|rhythmbox)
            echo "media" ;;
        discord|telegram*|slack|signal|email|mail*)
            echo "messaging" ;;
        battery|upower|ash-hw)
            echo "system" ;;
        network|ash-net|vpn|wireguard)
            echo "network" ;;
        docker|podman|kubernetes)
            echo "devops" ;;
        ash-theme|ash-wallpaper|ash-color)
            echo "theme" ;;
        ash-snapshot|ash-backup)
            echo "backup" ;;
        ash-mode|ash-plugin)
            echo "ash" ;;
        github|gitlab|ash-update|pacman|flatpak|paru|yay)
            echo "development" ;;
        calendar|khal|calcurse|todoman)
            echo "calendar" ;;
        screenshot|grim|grimblast|flameshot)
            echo "screenshot" ;;
        dunst|ash-*)
            echo "ash" ;;
        polkit*|gpg|ssh*|firewall)
            echo "security" ;;
        volume|brightness|pipewire)
            echo "osd" ;;
        systemd|cups|cron)
            echo "system" ;;
        home-assistant)
            echo "home" ;;
        *)
            echo "other" ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────────
# 📝  WRITE LOG ENTRY
# ──────────────────────────────────────────────────────────────────────────────

_write_log() {
    local entry="${1:-}"

    if [[ -z "${entry}" ]]; then
        return 1
    fi

    # Write to main log
    printf '%s\n' "${entry}" >> "${NOTIF_LOG}" 2>/dev/null || true

    # Write to daily log
    printf '%s\n' "${entry}" >> "${DAILY_LOG}" 2>/dev/null || true
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔍  SEARCH INDEX UPDATE
# ──────────────────────────────────────────────────────────────────────────────

_update_search_index() {
    local entry="${1:-}"

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    # Append to TSV search index:
    # timestamp<TAB>app<TAB>urgency<TAB>summary<TAB>body
    local ts app urgency summary body
    ts="$(printf '%s' "${entry}" | jq -r '.timestamp' 2>/dev/null || echo '')"
    app="${APP}"
    urgency="${URGENCY}"
    summary="${SUMMARY}"
    body="${BODY}"

    printf '%s\t%s\t%s\t%s\t%s\n' \
        "${ts}" "${app}" "${urgency}" \
        "${summary:0:100}" "${body:0:200}" \
        >> "${SEARCH_INDEX}" 2>/dev/null || true

    # Limit search index size (keep last 5000 entries)
    if [[ -f "${SEARCH_INDEX}" ]]; then
        local line_count
        line_count="$(wc -l < "${SEARCH_INDEX}" 2>/dev/null || echo 0)"
        if (( line_count > 5000 )); then
            tail -n 4000 "${SEARCH_INDEX}" > "${SEARCH_INDEX}.tmp" && \
                mv "${SEARCH_INDEX}.tmp" "${SEARCH_INDEX}" || true
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 📊  ANALYTICS UPDATE
# ──────────────────────────────────────────────────────────────────────────────

_update_analytics() {
    if ! command -v jq &>/dev/null; then
        return 0
    fi

    local today
    today="$(_today)"

    local app_lower="${APP,,}"
    local category
    category="$(_categorize_app "${APP}")"
    local urgency_lower="${URGENCY,,}"

    # Initialize stats file if missing
    if [[ ! -f "${STATS_FILE}" ]]; then
        cat > "${STATS_FILE}" <<'JSON'
{
  "total": 0,
  "by_app": {},
  "by_category": {},
  "by_urgency": {"low": 0, "normal": 0, "critical": 0},
  "by_day": {},
  "by_hour": {},
  "critical_events": [],
  "last_updated": ""
}
JSON
    fi

    # Update stats atomically with jq
    local tmp_stats
    tmp_stats="$(mktemp)"

    jq \
        --arg app "${app_lower}" \
        --arg cat "${category}" \
        --arg urg "${urgency_lower}" \
        --arg day "${today}" \
        --arg hour "$(_hour)" \
        --arg ts "$(_iso_timestamp)" \
        --arg summary "${SUMMARY:0:100}" \
        '
        .total += 1 |
        .by_app[$app] = ((.by_app[$app] // 0) + 1) |
        .by_category[$cat] = ((.by_category[$cat] // 0) + 1) |
        .by_urgency[$urg] = ((.by_urgency[$urg] // 0) + 1) |
        .by_day[$day] = ((.by_day[$day] // 0) + 1) |
        .by_hour[$hour] = ((.by_hour[$hour] // 0) + 1) |
        .last_updated = $ts |
        if $urg == "critical" then
            .critical_events = (
                [{"ts": $ts, "app": $app, "summary": $summary}] +
                .critical_events
            )[:50]
        else . end
        ' \
        "${STATS_FILE}" > "${tmp_stats}" 2>/dev/null && \
        mv "${tmp_stats}" "${STATS_FILE}" || \
        rm -f "${tmp_stats}"
}

# ──────────────────────────────────────────────────────────────────────────────
# 📅  DAILY SUMMARY TRACKING
# ──────────────────────────────────────────────────────────────────────────────

_update_daily_summary() {
    local daily_summary="${ANALYTICS_DIR}/daily-$(_today).json"

    if ! command -v jq &>/dev/null; then
        return 0
    fi

    if [[ ! -f "${daily_summary}" ]]; then
        cat > "${daily_summary}" <<JSON
{
  "date": "$(_today)",
  "total": 0,
  "by_app": {},
  "by_urgency": {"low": 0, "normal": 0, "critical": 0},
  "most_common": [],
  "first_notification": "$(_iso_timestamp)",
  "last_notification": "$(_iso_timestamp)"
}
JSON
    fi

    local app_lower="${APP,,}"
    local urgency_lower="${URGENCY,,}"
    local tmp
    tmp="$(mktemp)"

    jq \
        --arg app "${app_lower}" \
        --arg urg "${urgency_lower}" \
        --arg ts "$(_iso_timestamp)" \
        '
        .total += 1 |
        .by_app[$app] = ((.by_app[$app] // 0) + 1) |
        .by_urgency[$urg] = ((.by_urgency[$urg] // 0) + 1) |
        .last_notification = $ts |
        .most_common = (
            .by_app | to_entries |
            sort_by(-.value) |
            map(.key) |
            .[0:10]
        )
        ' \
        "${daily_summary}" > "${tmp}" 2>/dev/null && \
        mv "${tmp}" "${daily_summary}" || \
        rm -f "${tmp}"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🗜️  LOG ROTATION & CLEANUP
# ──────────────────────────────────────────────────────────────────────────────

_rotate_logs() {
    # Check main log size
    if [[ -f "${NOTIF_LOG}" ]]; then
        local log_size_bytes
        log_size_bytes="$(stat -c%s "${NOTIF_LOG}" 2>/dev/null || echo 0)"
        local max_bytes=$(( MAX_LOG_SIZE_MB * 1024 * 1024 ))

        if (( log_size_bytes > max_bytes )); then
            local archive_name
            archive_name="${LOG_DIR}/notifications-archive-$(date +%Y%m%d%H%M%S).jsonl.gz"

            gzip -c "${NOTIF_LOG}" > "${archive_name}" 2>/dev/null && \
                truncate -s 0 "${NOTIF_LOG}" && \
                printf '{"event":"log_rotated","archive":"%s","timestamp":"%s"}\n' \
                    "${archive_name}" "$(_iso_timestamp)" \
                    >> "${NOTIF_LOG}" || true
        fi
    fi

    # Clean old daily logs
    find "${LOG_DIR}" \
        -name "notifications-20*.jsonl" \
        -type f \
        -mtime +"${MAX_HISTORY_DAYS}" \
        -delete \
        2>/dev/null || true

    # Clean old daily analytics
    find "${ANALYTICS_DIR}" \
        -name "daily-20*.json" \
        -type f \
        -mtime +"${MAX_HISTORY_DAYS}" \
        -delete \
        2>/dev/null || true

    # Trim search index
    if [[ -f "${SEARCH_INDEX}" ]]; then
        local lines
        lines="$(wc -l < "${SEARCH_INDEX}" 2>/dev/null || echo 0)"
        if (( lines > 10000 )); then
            tail -n 8000 "${SEARCH_INDEX}" > "${SEARCH_INDEX}.tmp" && \
                mv "${SEARCH_INDEX}.tmp" "${SEARCH_INDEX}" || true
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 📜  SESSION TRACKING
# ──────────────────────────────────────────────────────────────────────────────

_update_session() {
    if ! command -v jq &>/dev/null; then
        return 0
    fi

    local session_id
    session_id="$(_get_session_id)"

    if [[ ! -f "${SESSION_FILE}" ]]; then
        cat > "${SESSION_FILE}" <<JSON
{
  "session_id": "${session_id}",
  "started": "$(_iso_timestamp)",
  "notification_count": 0,
  "by_urgency": {"low": 0, "normal": 0, "critical": 0},
  "apps_seen": [],
  "last_notification": null
}
JSON
    fi

    local app_lower="${APP,,}"
    local urgency_lower="${URGENCY,,}"
    local tmp
    tmp="$(mktemp)"

    jq \
        --arg app "${app_lower}" \
        --arg urg "${urgency_lower}" \
        --arg ts "$(_iso_timestamp)" \
        --arg summary "${SUMMARY:0:80}" \
        '
        .notification_count += 1 |
        .by_urgency[$urg] = ((.by_urgency[$urg] // 0) + 1) |
        .apps_seen = ((.apps_seen + [$app]) | unique) |
        .last_notification = {
            "timestamp": $ts,
            "summary": $summary,
            "urgency": $urg
        }
        ' \
        "${SESSION_FILE}" > "${tmp}" 2>/dev/null && \
        mv "${tmp}" "${SESSION_FILE}" || \
        rm -f "${tmp}"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🌟  SPECIAL EVENT TRACKING
# ──────────────────────────────────────────────────────────────────────────────

_track_special_events() {
    local urgency_lower="${URGENCY,,}"

    # Track critical events separately
    if [[ "${urgency_lower}" == "critical" ]]; then
        local critical_log="${LOG_DIR}/critical-events.jsonl"
        local entry="${1:-}"
        printf '%s\n' "${entry}" >> "${critical_log}" 2>/dev/null || true
    fi

    # Track ASH events
    local app_lower="${APP,,}"
    if [[ "${app_lower}" == ash-* ]]; then
        local ash_log="${LOG_DIR}/ash-events.jsonl"
        local entry="${1:-}"
        printf '%s\n' "${entry}" >> "${ash_log}" 2>/dev/null || true
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🏷️  SMART TAGGING
# ──────────────────────────────────────────────────────────────────────────────

_add_smart_tags() {
    local entry="${1:-}"

    if ! command -v jq &>/dev/null; then
        printf '%s\n' "${entry}"
        return
    fi

    local tags="[]"
    local summary_lower="${SUMMARY,,}"
    local body_lower="${BODY,,}"

    # Build tags array
    local tag_list=()

    [[ "${urgency_lower:-normal}" == "critical" ]] && \
        tag_list+=("critical")

    [[ "${summary_lower}" == *"error"* ]] || \
    [[ "${body_lower}" == *"failed"* ]] && \
        tag_list+=("error")

    [[ "${summary_lower}" == *"success"* ]] || \
    [[ "${summary_lower}" == *"complete"* ]] && \
        tag_list+=("success")

    [[ "${summary_lower}" == *"update"* ]] && \
        tag_list+=("update")

    [[ "${summary_lower}" == *"security"* ]] || \
    [[ "${summary_lower}" == *"auth"* ]] && \
        tag_list+=("security")

    if (( ${#tag_list[@]} > 0 )); then
        local tags_json
        tags_json="$(printf '"%s",' "${tag_list[@]}" | sed 's/,$//')"
        printf '%s' "${entry}" | jq \
            --argjson tags "[${tags_json}]" \
            '. + {"tags": $tags}' \
            2>/dev/null || printf '%s' "${entry}"
    else
        printf '%s' "${entry}" | jq \
            '. + {"tags": []}' \
            2>/dev/null || printf '%s' "${entry}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🚀  MAIN ENTRY POINT
# ──────────────────────────────────────────────────────────────────────────────

main() {
    _ensure_dirs

    # Skip suppressed notifications
    if _is_suppressed; then
        exit 0
    fi

    # Build JSON entry
    local entry
    entry="$(_build_json_entry)"

    # Add smart tags if jq available
    if command -v jq &>/dev/null; then
        entry="$(_add_smart_tags "${entry}")"
    fi

    # Core operations (order matters for performance)
    _write_log "${entry}"
    _update_search_index "${entry}"
    _track_special_events "${entry}"

    # Analytics (async to not block notification display)
    {
        _update_analytics
        _update_daily_summary
        _update_session
    } &>/dev/null &

    # Periodic rotation (1% chance per notification = roughly every 100)
    if (( RANDOM % 100 == 0 )); then
        _rotate_logs &>/dev/null &
    fi
}

main "$@"