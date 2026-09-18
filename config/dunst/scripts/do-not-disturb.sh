#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔕 ASH DOTFILES v5.0 OMEGA — DO NOT DISTURB CONTROLLER                    ║
# ║  Smart DND • Schedules • Focus • Exceptions • Multi-backend • Waybar sync  ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 📁 Location  : ~/.config/dunst/scripts/do-not-disturb.sh
# 📦 Requires  : bash ≥ 5.0, dunst, dunstctl, notify-send, jq
#               Optional: swaync, waybar, hyprctl, playerctl
# 🔗 Called by : keybind / waybar / ash-cli / systemd timer
# 🎯 Purpose   : Full-featured Do Not Disturb management system
#
# Usage:
#   do-not-disturb.sh toggle              # Toggle DND on/off
#   do-not-disturb.sh on                  # Enable DND
#   do-not-disturb.sh off                 # Disable DND
#   do-not-disturb.sh status              # Show current status
#   do-not-disturb.sh status --json       # JSON status output
#   do-not-disturb.sh timer 30            # Enable for 30 minutes
#   do-not-disturb.sh timer 1h            # Enable for 1 hour
#   do-not-disturb.sh schedule            # Apply scheduled DND
#   do-not-disturb.sh focus               # Focus mode DND
#   do-not-disturb.sh allow <app>         # Add exception
#   do-not-disturb.sh deny <app>          # Remove exception
#   do-not-disturb.sh exceptions          # List exceptions
#   do-not-disturb.sh history             # Show DND history
#   do-not-disturb.sh waybar              # Output waybar module JSON
#
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail
IFS=$'\n\t'

# ──────────────────────────────────────────────────────────────────────────────
# 📁  PATHS & CONSTANTS
# ──────────────────────────────────────────────────────────────────────────────

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly ASH_DATA="${XDG_DATA_HOME:-$HOME/.local/share}/ash"
readonly ASH_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/ash"
readonly DND_STATE_DIR="${ASH_DATA}/state/dnd"
readonly DND_LOG="${ASH_DATA}/logs/dnd.log"

# State files
readonly DND_STATE_FILE="${DND_STATE_DIR}/dnd.json"
readonly DND_TIMER_FILE="${DND_STATE_DIR}/timer.json"
readonly DND_SCHEDULE_FILE="${ASH_CONFIG}/dnd-schedule.json"
readonly DND_EXCEPTIONS_FILE="${DND_STATE_DIR}/exceptions.json"
readonly DND_HISTORY_FILE="${DND_STATE_DIR}/history.jsonl"

# Icons
readonly ICON_DND_ON="🔕"
readonly ICON_DND_OFF="🔔"
readonly ICON_FOCUS="🧘"
readonly ICON_TIMER="⏱️"
readonly ICON_SCHEDULE="📅"

# Colors for output
readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly MAGENTA=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly RESET=$'\033[0m'

# ──────────────────────────────────────────────────────────────────────────────
# 🛠️  CORE UTILITIES
# ──────────────────────────────────────────────────────────────────────────────

_ensure_dirs() {
    mkdir -p \
        "${DND_STATE_DIR}" \
        "$(dirname "${DND_LOG}")" \
        2>/dev/null || true
}

_log() {
    local level="${1:-INFO}"
    local message="${2:-}"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '[%s] [%-5s] %s\n' "${ts}" "${level}" "${message}" \
        >> "${DND_LOG}" 2>/dev/null || true
}

_now_unix() {
    date +%s
}

_now_iso() {
    date '+%Y-%m-%dT%H:%M:%S'
}

_current_hour() {
    date '+%H' | sed 's/^0//'  # Remove leading zero
}

_current_minute() {
    date '+%M' | sed 's/^0//'
}

_current_day() {
    date '+%A' | tr '[:upper:]' '[:lower:]'  # monday, tuesday...
}

# ──────────────────────────────────────────────────────────────────────────────
# 💾  STATE MANAGEMENT
# ──────────────────────────────────────────────────────────────────────────────

_init_state() {
    if [[ ! -f "${DND_STATE_FILE}" ]]; then
        cat > "${DND_STATE_FILE}" <<JSON
{
  "enabled": false,
  "mode": "off",
  "activated_at": null,
  "deactivated_at": null,
  "reason": null,
  "auto_disable_at": null,
  "focus_mode": false,
  "snoozed_until": null,
  "total_activations": 0,
  "total_duration_seconds": 0
}
JSON
    fi
}

_init_exceptions() {
    if [[ ! -f "${DND_EXCEPTIONS_FILE}" ]]; then
        cat > "${DND_EXCEPTIONS_FILE}" <<'JSON'
{
  "always_allow": [
    "ash-snapshot",
    "battery",
    "ash-hw",
    "ash-firewall",
    "home-assistant"
  ],
  "allow_urgency": ["critical"],
  "custom": []
}
JSON
    fi
}

_init_schedule() {
    if [[ ! -f "${DND_SCHEDULE_FILE}" ]]; then
        cat > "${DND_SCHEDULE_FILE}" <<'JSON'
{
  "enabled": true,
  "rules": [
    {
      "name": "Night Sleep",
      "days": ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"],
      "start": "23:00",
      "end": "08:00",
      "mode": "full"
    },
    {
      "name": "Work Focus",
      "days": ["monday","tuesday","wednesday","thursday","friday"],
      "start": "09:00",
      "end": "12:00",
      "mode": "partial",
      "allow_urgency": ["critical", "normal"]
    },
    {
      "name": "Lunch Break",
      "days": ["monday","tuesday","wednesday","thursday","friday"],
      "start": "12:00",
      "end": "13:00",
      "mode": "off"
    },
    {
      "name": "Afternoon Focus",
      "days": ["monday","tuesday","wednesday","thursday","friday"],
      "start": "14:00",
      "end": "17:00",
      "mode": "partial",
      "allow_urgency": ["critical"]
    }
  ]
}
JSON
    fi
}

_read_state() {
    if [[ ! -f "${DND_STATE_FILE}" ]]; then
        _init_state
    fi
    cat "${DND_STATE_FILE}"
}

_write_state() {
    local new_state="${1:-}"
    if [[ -n "${new_state}" ]]; then
        printf '%s\n' "${new_state}" > "${DND_STATE_FILE}"
    fi
}

_is_enabled() {
    if ! command -v jq &>/dev/null; then
        # Fallback: check dunstctl
        dunstctl is-paused 2>/dev/null | grep -q "true"
        return $?
    fi

    local state
    state="$(_read_state)"
    local enabled
    enabled="$(printf '%s' "${state}" | jq -r '.enabled' 2>/dev/null)"
    [[ "${enabled}" == "true" ]]
}

_get_mode() {
    if command -v jq &>/dev/null; then
        _read_state | jq -r '.mode' 2>/dev/null || echo "off"
    else
        if _is_enabled; then echo "on"; else echo "off"; fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔕  DUNST CONTROL
# ──────────────────────────────────────────────────────────────────────────────

_dunst_pause() {
    dunstctl set-paused true 2>/dev/null || \
        kill -s USR1 "$(pgrep -x dunst 2>/dev/null)" 2>/dev/null || true
}

_dunst_resume() {
    dunstctl set-paused false 2>/dev/null || \
        kill -s USR2 "$(pgrep -x dunst 2>/dev/null)" 2>/dev/null || true
}

_dunst_is_paused() {
    dunstctl is-paused 2>/dev/null | grep -q "true"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔔  SWAYNC CONTROL (fallback/companion)
# ──────────────────────────────────────────────────────────────────────────────

_swaync_dnd() {
    local enable="${1:-true}"
    if command -v swaync-client &>/dev/null; then
        if [[ "${enable}" == "true" ]]; then
            swaync-client --dnd-on &>/dev/null || true
        else
            swaync-client --dnd-off &>/dev/null || true
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 📊  WAYBAR INTEGRATION
# ──────────────────────────────────────────────────────────────────────────────

_update_waybar() {
    # Signal waybar to refresh custom module
    pkill -RTMIN+4 waybar &>/dev/null || true
}

_waybar_output() {
    local enabled
    enabled="$(_is_enabled && echo true || echo false)"

    local mode
    mode="$(_get_mode)"

    local text tooltip class

    if [[ "${enabled}" == "true" ]]; then
        case "${mode}" in
            focus)
                text="${ICON_FOCUS}"
                tooltip="Focus Mode — DND Active"
                class="dnd-focus" ;;
            timer)
                local until=""
                if command -v jq &>/dev/null && [[ -f "${DND_STATE_FILE}" ]]; then
                    local auto_off
                    auto_off="$(jq -r '.auto_disable_at // empty' "${DND_STATE_FILE}" 2>/dev/null)"
                    if [[ -n "${auto_off}" ]]; then
                        local remaining
                        remaining="$(( auto_off - $(_now_unix) ))"
                        if (( remaining > 0 )); then
                            until=" $(( remaining / 60 ))m"
                        fi
                    fi
                fi
                text="${ICON_TIMER}${until}"
                tooltip="DND Timer Active"
                class="dnd-timer" ;;
            schedule)
                text="${ICON_SCHEDULE}"
                tooltip="DND Schedule Active"
                class="dnd-schedule" ;;
            *)
                text="${ICON_DND_ON}"
                tooltip="Do Not Disturb — Active"
                class="dnd-on" ;;
        esac
    else
        text="${ICON_DND_OFF}"
        tooltip="Notifications — Active"
        class="dnd-off"
    fi

    # Add notification count to tooltip
    local notif_count=0
    if command -v dunstctl &>/dev/null; then
        notif_count="$(dunstctl count waiting 2>/dev/null || echo 0)"
    fi

    if (( notif_count > 0 )); then
        tooltip="${tooltip} (${notif_count} waiting)"
    fi

    # Output Waybar JSON
    printf '{"text":"%s","tooltip":"%s","class":"%s","percentage":%s}\n' \
        "${text}" \
        "${tooltip}" \
        "${class}" \
        "$(${enabled} && echo 100 || echo 0)"
}

# ──────────────────────────────────────────────────────────────────────────────
# 📢  NOTIFICATIONS
# ──────────────────────────────────────────────────────────────────────────────

_notify_dnd_on() {
    local reason="${1:-Manual}"
    local extra="${2:-}"

    local body="${reason}"
    if [[ -n "${extra}" ]]; then
        body="${reason}\n${extra}"
    fi

    notify-send \
        --app-name="ash-dnd" \
        --urgency="low" \
        --icon="notifications-disabled-symbolic" \
        --expire-time="3000" \
        "${ICON_DND_ON} Do Not Disturb" \
        "${body}" \
        2>/dev/null || true
}

_notify_dnd_off() {
    local reason="${1:-Manual}"

    # Count waiting notifications
    local waiting=0
    if command -v dunstctl &>/dev/null; then
        waiting="$(dunstctl count waiting 2>/dev/null || echo 0)"
    fi

    local body="${reason}"
    if (( waiting > 0 )); then
        body="${reason}\n${waiting} notifications waiting"
    fi

    notify-send \
        --app-name="ash-dnd" \
        --urgency="low" \
        --icon="notification-symbolic" \
        --expire-time="3000" \
        "${ICON_DND_OFF} Notifications Restored" \
        "${body}" \
        2>/dev/null || true
}

# ──────────────────────────────────────────────────────────────────────────────
# 📜  HISTORY TRACKING
# ──────────────────────────────────────────────────────────────────────────────

_record_history() {
    local event="${1:-}"
    local reason="${2:-}"
    local duration="${3:-0}"

    local entry
    entry="$(cat <<JSON
{"timestamp":"$(_now_iso)","unix":$(_now_unix),"event":"${event}","reason":"${reason}","duration_seconds":${duration}}
JSON
)"
    printf '%s\n' "${entry}" >> "${DND_HISTORY_FILE}" 2>/dev/null || true

    # Trim history to last 500 entries
    if [[ -f "${DND_HISTORY_FILE}" ]]; then
        local lines
        lines="$(wc -l < "${DND_HISTORY_FILE}" 2>/dev/null || echo 0)"
        if (( lines > 500 )); then
            tail -n 400 "${DND_HISTORY_FILE}" > \
                "${DND_HISTORY_FILE}.tmp" && \
                mv "${DND_HISTORY_FILE}.tmp" \
                   "${DND_HISTORY_FILE}" || true
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# ⚡  CORE DND ACTIONS
# ──────────────────────────────────────────────────────────────────────────────

_enable_dnd() {
    local mode="${1:-manual}"
    local reason="${2:-Do Not Disturb enabled}"
    local duration_secs="${3:-0}"  # 0 = permanent

    _log "INFO" "Enabling DND: mode=${mode} reason=${reason}"

    # Pause dunst
    _dunst_pause

    # Sync swaync
    _swaync_dnd "true"

    # Update state
    local now_unix
    now_unix="$(_now_unix)"

    local auto_disable="null"
    if (( duration_secs > 0 )); then
        auto_disable="$(( now_unix + duration_secs ))"
    fi

    if command -v jq &>/dev/null && [[ -f "${DND_STATE_FILE}" ]]; then
        local new_state
        new_state="$(jq \
            --argjson now "${now_unix}" \
            --arg mode "${mode}" \
            --arg reason "${reason}" \
            --argjson auto "${auto_disable}" \
            '
            .enabled = true |
            .mode = $mode |
            .activated_at = $now |
            .reason = $reason |
            .auto_disable_at = $auto |
            .focus_mode = ($mode == "focus") |
            .total_activations += 1
            ' \
            "${DND_STATE_FILE}" 2>/dev/null)"
        _write_state "${new_state}"
    fi

    # Hyprland mode indicator
    if command -v hyprctl &>/dev/null && [[ "${mode}" == "focus" ]]; then
        hyprctl keyword "general:col.active_border" \
            "rgba(cba6f7ff) rgba(89b4faff) 45deg" \
            &>/dev/null || true
    fi

    # Record history
    _record_history "enabled" "${reason}" "${duration_secs}"

    # Update waybar
    _update_waybar

    _log "SUCCESS" "DND enabled: ${mode}"
}

_disable_dnd() {
    local reason="${1:-Do Not Disturb disabled}"

    _log "INFO" "Disabling DND: reason=${reason}"

    # Calculate duration
    local duration=0
    if command -v jq &>/dev/null && [[ -f "${DND_STATE_FILE}" ]]; then
        local activated_at
        activated_at="$(jq -r '.activated_at // 0' "${DND_STATE_FILE}" 2>/dev/null)"
        if [[ "${activated_at}" != "null" ]] && \
           [[ "${activated_at}" != "0" ]]; then
            duration="$(( $(_now_unix) - activated_at ))"
        fi
    fi

    # Resume dunst
    _dunst_resume

    # Sync swaync
    _swaync_dnd "false"

    # Update state
    local now_unix
    now_unix="$(_now_unix)"

    if command -v jq &>/dev/null && [[ -f "${DND_STATE_FILE}" ]]; then
        local new_state
        new_state="$(jq \
            --argjson now "${now_unix}" \
            --arg reason "${reason}" \
            --argjson dur "${duration}" \
            '
            .enabled = false |
            .mode = "off" |
            .deactivated_at = $now |
            .reason = $reason |
            .auto_disable_at = null |
            .focus_mode = false |
            .total_duration_seconds += $dur
            ' \
            "${DND_STATE_FILE}" 2>/dev/null)"
        _write_state "${new_state}"
    fi

    # Restore Hyprland border
    if command -v hyprctl &>/dev/null; then
        # Restore theme colors
        local ash_colors="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/themes/colors.conf"
        if [[ -f "${ash_colors}" ]]; then
            hyprctl reload &>/dev/null || true
        fi
    fi

    # Record history
    _record_history "disabled" "${reason}" "${duration}"

    # Update waybar
    _update_waybar

    _log "SUCCESS" "DND disabled (duration: ${duration}s)"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔄  TOGGLE
# ──────────────────────────────────────────────────────────────────────────────

cmd_toggle() {
    if _is_enabled; then
        _disable_dnd "Toggled off"
        _notify_dnd_off "Toggled off"
        printf '%b%s OFF%b\n' "${GREEN}" "${ICON_DND_OFF}" "${RESET}"
    else
        _enable_dnd "manual" "Toggled on"
        _notify_dnd_on "Toggled on"
        printf '%b%s ON%b\n' "${YELLOW}" "${ICON_DND_ON}" "${RESET}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# ✅  ENABLE
# ──────────────────────────────────────────────────────────────────────────────

cmd_on() {
    local reason="${1:-Manual activation}"

    if _is_enabled; then
        printf '%bDND already active%b\n' "${YELLOW}" "${RESET}"
        return 0
    fi

    _enable_dnd "manual" "${reason}"
    _notify_dnd_on "${reason}"
    printf '%b%s Do Not Disturb ENABLED%b\n' "${YELLOW}" "${ICON_DND_ON}" "${RESET}"
}

# ──────────────────────────────────────────────────────────────────────────────
# ❌  DISABLE
# ──────────────────────────────────────────────────────────────────────────────

cmd_off() {
    local reason="${1:-Manual deactivation}"

    if ! _is_enabled; then
        printf '%bDND not active%b\n' "${DIM}" "${RESET}"
        return 0
    fi

    _disable_dnd "${reason}"
    _notify_dnd_off "${reason}"
    printf '%b%s Notifications RESTORED%b\n' "${GREEN}" "${ICON_DND_OFF}" "${RESET}"
}

# ──────────────────────────────────────────────────────────────────────────────
# ⏱️  TIMER
# ──────────────────────────────────────────────────────────────────────────────

cmd_timer() {
    local duration_arg="${1:-30}"
    local duration_secs

    # Parse duration: 30 = 30 minutes, 1h = 60 minutes, 90m = 90 minutes
    if [[ "${duration_arg}" =~ ^([0-9]+)h$ ]]; then
        duration_secs="$(( BASH_REMATCH[1] * 3600 ))"
    elif [[ "${duration_arg}" =~ ^([0-9]+)m$ ]]; then
        duration_secs="$(( BASH_REMATCH[1] * 60 ))"
    elif [[ "${duration_arg}" =~ ^([0-9]+)s$ ]]; then
        duration_secs="${BASH_REMATCH[1]}"
    elif [[ "${duration_arg}" =~ ^[0-9]+$ ]]; then
        # Default unit: minutes
        duration_secs="$(( duration_arg * 60 ))"
    else
        printf '%bInvalid duration: %s%b\n' "${RED}" "${duration_arg}" "${RESET}"
        printf 'Usage: %s timer <minutes|1h|30m|90s>\n' "${SCRIPT_NAME}"
        exit 1
    fi

    local human_duration
    if (( duration_secs >= 3600 )); then
        human_duration="$(( duration_secs / 3600 ))h $(( (duration_secs % 3600) / 60 ))m"
    elif (( duration_secs >= 60 )); then
        human_duration="$(( duration_secs / 60 )) minutes"
    else
        human_duration="${duration_secs} seconds"
    fi

    local disable_at
    disable_at="$(( $(_now_unix) + duration_secs ))"

    local disable_time
    disable_time="$(date -d "@${disable_at}" '+%H:%M' 2>/dev/null || \
                   date '+%H:%M')"

    _enable_dnd "timer" "Timer: ${human_duration}" "${duration_secs}"
    _notify_dnd_on \
        "${ICON_TIMER} Timer: ${human_duration}" \
        "Restores at ${disable_time}"

    printf '%b%s DND Timer: %s (until %s)%b\n' \
        "${YELLOW}" "${ICON_TIMER}" \
        "${human_duration}" "${disable_time}" "${RESET}"

    # Save timer file
    cat > "${DND_TIMER_FILE}" <<JSON
{
  "enabled": true,
  "duration_seconds": ${duration_secs},
  "disable_at": ${disable_at},
  "disable_time": "${disable_time}",
  "created_at": $(_now_unix)
}
JSON

    # Schedule auto-disable using systemd or background process
    if command -v systemd-run &>/dev/null; then
        systemd-run \
            --user \
            --on-active="${duration_secs}s" \
            --unit="ash-dnd-timer" \
            --description="ASH DND Timer" \
            "${SCRIPT_DIR}/do-not-disturb.sh" off "Timer expired" \
            &>/dev/null || true
    else
        # Fallback: background sleep
        (
            sleep "${duration_secs}"
            "${SCRIPT_DIR}/do-not-disturb.sh" off "Timer expired" \
                &>/dev/null || true
        ) &
        disown
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🧘  FOCUS MODE
# ──────────────────────────────────────────────────────────────────────────────

cmd_focus() {
    local duration_arg="${1:-25}"  # Default: 25 minutes (Pomodoro)
    local duration_secs="$(( duration_arg * 60 ))"

    _enable_dnd "focus" "Focus Mode — ${duration_arg}min Pomodoro" \
        "${duration_secs}"

    # Additional focus mode actions
    # Pause media
    if command -v playerctl &>/dev/null; then
        playerctl pause &>/dev/null || true
    fi

    # Activate Hyprland focus shader
    if command -v hyprctl &>/dev/null; then
        hyprctl keyword "decoration:blur:enabled" "false" &>/dev/null || true
    fi

    # Start ASH focus mode
    if command -v ash &>/dev/null; then
        ash mode focus &>/dev/null & true
    fi

    local disable_time
    disable_time="$(date -d "@$(( $(_now_unix) + duration_secs ))" \
        '+%H:%M' 2>/dev/null || date '+%H:%M')"

    _notify_dnd_on \
        "${ICON_FOCUS} Focus Mode Active" \
        "${duration_arg} min session until ${disable_time}"

    printf '%b%s Focus Mode: %s min (until %s)%b\n' \
        "${MAGENTA}" "${ICON_FOCUS}" \
        "${duration_arg}" "${disable_time}" "${RESET}"

    # Auto-disable after focus period
    if command -v systemd-run &>/dev/null; then
        systemd-run \
            --user \
            --on-active="${duration_secs}s" \
            --unit="ash-dnd-focus" \
            --description="ASH Focus Timer" \
            "${SCRIPT_DIR}/do-not-disturb.sh" off "Focus session complete" \
            &>/dev/null || true
    else
        (
            sleep "${duration_secs}"
            "${SCRIPT_DIR}/do-not-disturb.sh" off "Focus session complete" \
                &>/dev/null || true
        ) &
        disown
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 📅  SCHEDULE MANAGEMENT
# ──────────────────────────────────────────────────────────────────────────────

cmd_schedule() {
    _init_schedule

    if ! command -v jq &>/dev/null; then
        _log "WARN" "jq not available — schedule check skipped"
        return 0
    fi

    local schedule_enabled
    schedule_enabled="$(jq -r '.enabled' "${DND_SCHEDULE_FILE}" 2>/dev/null)"

    if [[ "${schedule_enabled}" != "true" ]]; then
        _log "DEBUG" "Schedule disabled"
        return 0
    fi

    local current_hour
    current_hour="$(_current_hour)"

    local current_minute
    current_minute="$(_current_minute)"

    local current_day
    current_day="$(_current_day)"

    local current_minutes="$(( current_hour * 60 + current_minute ))"

    # Check each rule
    local should_enable=false
    local active_rule=""
    local active_mode=""

    while IFS= read -r rule; do
        local rule_name days start end mode

        rule_name="$(printf '%s' "${rule}" | \
            jq -r '.name' 2>/dev/null)"
        start="$(printf '%s' "${rule}" | \
            jq -r '.start' 2>/dev/null)"
        end="$(printf '%s' "${rule}" | \
            jq -r '.end' 2>/dev/null)"
        mode="$(printf '%s' "${rule}" | \
            jq -r '.mode' 2>/dev/null)"

        # Check if current day matches
        local day_match
        day_match="$(printf '%s' "${rule}" | \
            jq -r --arg day "${current_day}" \
            '.days | map(ascii_downcase) | contains([$day])' \
            2>/dev/null)"

        if [[ "${day_match}" != "true" ]]; then
            continue
        fi

        # Parse times
        local start_h start_m end_h end_m
        IFS=':' read -r start_h start_m <<< "${start}"
        IFS=':' read -r end_h end_m <<< "${end}"

        start_h="${start_h#0}"  # Remove leading zero
        start_m="${start_m#0}"
        end_h="${end_h#0}"
        end_m="${end_m#0}"

        local start_mins="$(( start_h * 60 + start_m ))"
        local end_mins="$(( end_h * 60 + end_m ))"

        # Handle overnight rules (e.g., 23:00 - 08:00)
        local in_range=false
        if (( start_mins > end_mins )); then
            # Overnight rule
            if (( current_minutes >= start_mins )) || \
               (( current_minutes < end_mins )); then
                in_range=true
            fi
        else
            if (( current_minutes >= start_mins )) && \
               (( current_minutes < end_mins )); then
                in_range=true
            fi
        fi

        if [[ "${in_range}" == "true" ]]; then
            if [[ "${mode}" != "off" ]]; then
                should_enable=true
                active_rule="${rule_name}"
                active_mode="${mode}"
            fi
            break
        fi

    done < <(jq -c '.rules[]' "${DND_SCHEDULE_FILE}" 2>/dev/null)

    # Apply schedule decision
    if [[ "${should_enable}" == "true" ]]; then
        if ! _is_enabled; then
            _enable_dnd "schedule" "Schedule: ${active_rule}"
            _log "INFO" "Schedule enabled DND: ${active_rule} (${active_mode})"
        fi
    else
        # Only disable if it was schedule-enabled
        if _is_enabled; then
            local current_mode
            current_mode="$(_get_mode)"
            if [[ "${current_mode}" == "schedule" ]]; then
                _disable_dnd "Schedule ended"
                _log "INFO" "Schedule disabled DND"
            fi
        fi
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🚫  SNOOZE
# ──────────────────────────────────────────────────────────────────────────────

cmd_snooze() {
    local minutes="${1:-10}"

    # Temporarily disable DND for N minutes
    if ! _is_enabled; then
        printf '%bDND not active — nothing to snooze%b\n' \
            "${DIM}" "${RESET}"
        return 0
    fi

    local snooze_secs="$(( minutes * 60 ))"
    local restore_time
    restore_time="$(date -d "@$(( $(_now_unix) + snooze_secs ))" \
        '+%H:%M' 2>/dev/null || date '+%H:%M')"

    # Temporarily enable notifications
    _dunst_resume
    _swaync_dnd "false"

    _notify_dnd_off \
        "Snoozed for ${minutes} min (restores at ${restore_time})"

    printf '%b%s Snoozed: %s min (restores at %s)%b\n' \
        "${CYAN}" "💤" "${minutes}" "${restore_time}" "${RESET}"

    # Re-enable after snooze
    if command -v systemd-run &>/dev/null; then
        systemd-run \
            --user \
            --on-active="${snooze_secs}s" \
            --unit="ash-dnd-snooze" \
            --description="ASH DND Snooze" \
            "${SCRIPT_DIR}/do-not-disturb.sh" on "Snooze ended" \
            &>/dev/null || true
    else
        (
            sleep "${snooze_secs}"
            _dunst_pause
            _swaync_dnd "true"
            notify-send \
                --app-name="ash-dnd" \
                --urgency="low" \
                "${ICON_DND_ON} DND Restored" \
                "Snooze ended — DND active again" \
                2>/dev/null || true
        ) &
        disown
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔓  EXCEPTIONS MANAGEMENT
# ──────────────────────────────────────────────────────────────────────────────

cmd_allow() {
    local app="${1:-}"

    if [[ -z "${app}" ]]; then
        printf '%bUsage: %s allow <app_name>%b\n' \
            "${RED}" "${SCRIPT_NAME}" "${RESET}"
        exit 1
    fi

    _init_exceptions

    if command -v jq &>/dev/null; then
        local new_exceptions
        new_exceptions="$(jq \
            --arg app "${app}" \
            '.custom = (.custom + [$app] | unique)' \
            "${DND_EXCEPTIONS_FILE}" 2>/dev/null)"
        printf '%s\n' "${new_exceptions}" > "${DND_EXCEPTIONS_FILE}"
    fi

    printf '%b✅ Exception added: %s%b\n' "${GREEN}" "${app}" "${RESET}"
    _log "INFO" "Exception added: ${app}"
}

cmd_deny() {
    local app="${1:-}"

    if [[ -z "${app}" ]]; then
        printf '%bUsage: %s deny <app_name>%b\n' \
            "${RED}" "${SCRIPT_NAME}" "${RESET}"
        exit 1
    fi

    _init_exceptions

    if command -v jq &>/dev/null; then
        local new_exceptions
        new_exceptions="$(jq \
            --arg app "${app}" \
            '.custom = (.custom | map(select(. != $app)))' \
            "${DND_EXCEPTIONS_FILE}" 2>/dev/null)"
        printf '%s\n' "${new_exceptions}" > "${DND_EXCEPTIONS_FILE}"
    fi

    printf '%b🚫 Exception removed: %s%b\n' "${YELLOW}" "${app}" "${RESET}"
    _log "INFO" "Exception removed: ${app}"
}

cmd_exceptions() {
    _init_exceptions

    printf '\n%b%s DND Exceptions:%b\n' \
        "${BOLD}" "${ICON_DND_OFF}" "${RESET}"
    printf '%b━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━%b\n' \
        "${CYAN}" "${RESET}"

    if command -v jq &>/dev/null && [[ -f "${DND_EXCEPTIONS_FILE}" ]]; then
        printf '\n%bAlways Allowed Apps:%b\n' "${GREEN}" "${RESET}"
        jq -r '.always_allow[]' "${DND_EXCEPTIONS_FILE}" 2>/dev/null | \
            while IFS= read -r app; do
                printf '  %b✓%b %s\n' "${GREEN}" "${RESET}" "${app}"
            done

        printf '\n%bAllowed Urgency Levels:%b\n' "${BLUE}" "${RESET}"
        jq -r '.allow_urgency[]' "${DND_EXCEPTIONS_FILE}" 2>/dev/null | \
            while IFS= read -r urg; do
                printf '  %b•%b %s\n' "${BLUE}" "${RESET}" "${urg}"
            done

        printf '\n%bCustom Exceptions:%b\n' "${CYAN}" "${RESET}"
        local custom_count
        custom_count="$(jq -r '.custom | length' \
            "${DND_EXCEPTIONS_FILE}" 2>/dev/null || echo 0)"

        if (( custom_count == 0 )); then
            printf '  %b(none)%b\n' "${DIM}" "${RESET}"
        else
            jq -r '.custom[]' "${DND_EXCEPTIONS_FILE}" 2>/dev/null | \
                while IFS= read -r app; do
                    printf '  %b+%b %s\n' "${CYAN}" "${RESET}" "${app}"
                done
        fi
    fi

    printf '\n'
}

# ──────────────────────────────────────────────────────────────────────────────
# 📊  STATUS
# ──────────────────────────────────────────────────────────────────────────────

cmd_status() {
    local json_output=false
    if [[ "${1:-}" == "--json" ]]; then
        json_output=true
    fi

    local enabled
    enabled="$(_is_enabled && echo true || echo false)"

    local mode
    mode="$(_get_mode)"

    local dunst_paused
    dunst_paused="$(dunstctl is-paused 2>/dev/null || echo false)"

    local waiting_count=0
    if command -v dunstctl &>/dev/null; then
        waiting_count="$(dunstctl count waiting 2>/dev/null || echo 0)"
    fi

    if [[ "${json_output}" == "true" ]]; then
        cat <<JSON
{
  "enabled": ${enabled},
  "mode": "${mode}",
  "dunst_paused": ${dunst_paused},
  "waiting_notifications": ${waiting_count},
  "timestamp": "$(_now_iso)"
}
JSON
        return 0
    fi

    # Pretty status output
    printf '\n'
    printf '%b╔══════════════════════════════════════╗%b\n' "${CYAN}" "${RESET}"
    printf '%b║%b  %s Do Not Disturb Status          %b║%b\n' \
        "${CYAN}" "${RESET}" \
        "$(_is_enabled && printf '%b🔕 ACTIVE  %b' "${YELLOW}" "${RESET}" || \
           printf '%b🔔 INACTIVE%b' "${GREEN}" "${RESET}")" \
        "${CYAN}" "${RESET}"
    printf '%b╚══════════════════════════════════════╝%b\n' "${CYAN}" "${RESET}"
    printf '\n'

    printf '  %bStatus:%b     %s\n' "${BOLD}" "${RESET}" \
        "$(_is_enabled && printf '%bON%b' "${YELLOW}" "${RESET}" || \
           printf '%bOFF%b' "${GREEN}" "${RESET}")"

    printf '  %bMode:%b       %b%s%b\n' "${BOLD}" "${RESET}" \
        "${CYAN}" "${mode:-off}" "${RESET}"

    printf '  %bDunst:%b      %s\n' "${BOLD}" "${RESET}" \
        "$(${dunst_paused} && printf '%bPaused%b' "${YELLOW}" "${RESET}" || \
           printf '%bRunning%b' "${GREEN}" "${RESET}")"

    printf '  %bWaiting:%b    %b%s%b notifications\n' "${BOLD}" "${RESET}" \
        "$((waiting_count > 0)) && \
         printf '%b' "${YELLOW}" || printf '%b' "${GREEN}")" \
        "${waiting_count}" "${RESET}"

    # Show timer info
    if command -v jq &>/dev/null && [[ -f "${DND_STATE_FILE}" ]]; then
        local auto_off
        auto_off="$(jq -r '.auto_disable_at // empty' \
            "${DND_STATE_FILE}" 2>/dev/null)"

        if [[ -n "${auto_off}" ]] && [[ "${auto_off}" != "null" ]]; then
            local remaining
            remaining="$(( auto_off - $(_now_unix) ))"
            if (( remaining > 0 )); then
                local disable_time
                disable_time="$(date -d "@${auto_off}" '+%H:%M' 2>/dev/null)"
                printf '  %bExpires:%b    %s (%s min remaining)\n' \
                    "${BOLD}" "${RESET}" \
                    "${disable_time}" "$(( remaining / 60 ))"
            fi
        fi

        # Show stats
        local total_activations total_duration
        total_activations="$(jq -r '.total_activations // 0' \
            "${DND_STATE_FILE}" 2>/dev/null)"
        total_duration="$(jq -r '.total_duration_seconds // 0' \
            "${DND_STATE_FILE}" 2>/dev/null)"

        printf '\n  %bSession Stats:%b\n' "${BOLD}" "${RESET}"
        printf '  ├─ Activations: %b%s%b\n' \
            "${CYAN}" "${total_activations}" "${RESET}"
        printf '  └─ Total time:  %b%s min%b\n' \
            "${CYAN}" "$(( total_duration / 60 ))" "${RESET}"
    fi

    printf '\n'
}

# ──────────────────────────────────────────────────────────────────────────────
# 📜  HISTORY
# ──────────────────────────────────────────────────────────────────────────────

cmd_history() {
    local count="${1:-20}"

    printf '\n%b%s DND History (last %s events):%b\n\n' \
        "${BOLD}" "${ICON_DND_ON}" "${count}" "${RESET}"

    if [[ ! -f "${DND_HISTORY_FILE}" ]]; then
        printf '  %b(no history yet)%b\n\n' "${DIM}" "${RESET}"
        return 0
    fi

    if command -v jq &>/dev/null; then
        tail -n "${count}" "${DND_HISTORY_FILE}" | \
        while IFS= read -r entry; do
            local ts event reason duration
            ts="$(printf '%s' "${entry}" | \
                jq -r '.timestamp' 2>/dev/null)"
            event="$(printf '%s' "${entry}" | \
                jq -r '.event' 2>/dev/null)"
            reason="$(printf '%s' "${entry}" | \
                jq -r '.reason' 2>/dev/null)"
            duration="$(printf '%s' "${entry}" | \
                jq -r '.duration_seconds' 2>/dev/null)"

            local event_icon event_color
            case "${event}" in
                enabled)
                    event_icon="${ICON_DND_ON}"
                    event_color="${YELLOW}" ;;
                disabled)
                    event_icon="${ICON_DND_OFF}"
                    event_color="${GREEN}" ;;
                *)
                    event_icon="•"
                    event_color="${DIM}" ;;
            esac

            local duration_str=""
            if [[ "${duration}" != "0" ]] && \
               [[ "${duration}" != "null" ]]; then
                duration_str=" (${duration}s)"
            fi

            printf '  %b%s%b %b%-20s%b %s — %s%s\n' \
                "${event_color}" "${event_icon}" "${RESET}" \
                "${DIM}" "${ts}" "${RESET}" \
                "${event}" "${reason}" "${duration_str}"
        done
    else
        tail -n "${count}" "${DND_HISTORY_FILE}"
    fi

    printf '\n'
}

# ──────────────────────────────────────────────────────────────────────────────
# 📅  SCHEDULE VIEWER
# ──────────────────────────────────────────────────────────────────────────────

cmd_show_schedule() {
    _init_schedule

    printf '\n%b📅 DND Schedule:%b\n\n' "${BOLD}" "${RESET}"

    if ! command -v jq &>/dev/null; then
        cat "${DND_SCHEDULE_FILE}"
        return 0
    fi

    local enabled
    enabled="$(jq -r '.enabled' "${DND_SCHEDULE_FILE}" 2>/dev/null)"

    printf '  %bSchedule:%b %s\n\n' "${BOLD}" "${RESET}" \
        "$([[ "${enabled}" == "true" ]] && \
           printf '%bEnabled%b' "${GREEN}" "${RESET}" || \
           printf '%bDisabled%b' "${RED}" "${RESET}")"

    jq -c '.rules[]' "${DND_SCHEDULE_FILE}" 2>/dev/null | \
    while IFS= read -r rule; do
        local name start end mode days
        name="$(printf '%s' "${rule}" | jq -r '.name')"
        start="$(printf '%s' "${rule}" | jq -r '.start')"
        end="$(printf '%s' "${rule}" | jq -r '.end')"
        mode="$(printf '%s' "${rule}" | jq -r '.mode')"
        days="$(printf '%s' "${rule}" | \
            jq -r '.days | join(", ")')"

        printf '  %b%s%b\n' "${CYAN}" "${name}" "${RESET}"
        printf '  ├─ Time:  %s → %s\n' "${start}" "${end}"
        printf '  ├─ Mode:  %s\n' "${mode}"
        printf '  └─ Days:  %s\n\n' "${days}"
    done
}

# ──────────────────────────────────────────────────────────────────────────────
# 📱  WAYBAR OUTPUT
# ──────────────────────────────────────────────────────────────────────────────

cmd_waybar() {
    _waybar_output
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔧  ROFI MENU
# ──────────────────────────────────────────────────────────────────────────────

cmd_rofi() {
    if ! command -v rofi &>/dev/null; then
        printf '%bRofi not installed%b\n' "${RED}" "${RESET}"
        exit 1
    fi

    local enabled
    enabled="$(_is_enabled && echo true || echo false)"

    local options
    if [[ "${enabled}" == "true" ]]; then
        options="$(cat <<'EOF'
🔔 Disable DND
⏰ Snooze 10 minutes
📊 Show Status
📜 View History
📅 View Schedule
🚪 Cancel
EOF
)"
    else
        options="$(cat <<'EOF'
🔕 Enable DND
⏱️ Timer 30 min
⏱️ Timer 1 hour
🧘 Focus Mode (25 min)
📊 Show Status
📜 View History
📅 View Schedule
🚪 Cancel
EOF
)"
    fi

    local choice
    choice="$(printf '%s' "${options}" | rofi \
        -dmenu \
        -p "Do Not Disturb" \
        -theme-str 'window {width: 380px;}' \
        2>/dev/null || echo "")"

    case "${choice}" in
        *"Enable DND"*)     cmd_on ;;
        *"Disable DND"*)    cmd_off ;;
        *"Snooze"*)         cmd_snooze 10 ;;
        *"Timer 30"*)       cmd_timer 30 ;;
        *"Timer 1 hour"*)   cmd_timer 1h ;;
        *"Focus Mode"*)     cmd_focus 25 ;;
        *"Show Status"*)    cmd_status ;;
        *"View History"*)   cmd_history ;;
        *"View Schedule"*)  cmd_show_schedule ;;
        *"Cancel"*|"")      exit 0 ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────────
# 🆘  HELP
# ──────────────────────────────────────────────────────────────────────────────

cmd_help() {
    cat <<HELP

${BOLD}${CYAN}🔕 ASH Do Not Disturb Controller v5.0${RESET}

${BOLD}USAGE:${RESET}
  $(basename "$0") <command> [options]

${BOLD}COMMANDS:${RESET}
  ${GREEN}toggle${RESET}              Toggle DND on/off
  ${GREEN}on${RESET} [reason]         Enable DND
  ${GREEN}off${RESET} [reason]        Disable DND
  ${GREEN}timer${RESET} <duration>    Enable for duration (30, 1h, 90m, 45s)
  ${GREEN}focus${RESET} [minutes]     Focus mode (default: 25 min Pomodoro)
  ${GREEN}snooze${RESET} [minutes]    Temporarily disable (default: 10 min)
  ${GREEN}schedule${RESET}            Apply schedule rules (run via cron)
  ${GREEN}status${RESET} [--json]     Show current status
  ${GREEN}history${RESET} [count]     Show event history
  ${GREEN}allow${RESET} <app>         Add notification exception
  ${GREEN}deny${RESET} <app>          Remove notification exception
  ${GREEN}exceptions${RESET}          List all exceptions
  ${GREEN}schedule-view${RESET}       View schedule rules
  ${GREEN}waybar${RESET}              Output Waybar JSON module
  ${GREEN}rofi${RESET}                Show Rofi interactive menu
  ${GREEN}help${RESET}                Show this help

${BOLD}EXAMPLES:${RESET}
  $(basename "$0") toggle
  $(basename "$0") timer 45
  $(basename "$0") timer 2h
  $(basename "$0") focus 50
  $(basename "$0") snooze 15
  $(basename "$0") allow spotify
  $(basename "$0") status --json

${BOLD}WAYBAR MODULE:${RESET}
  Add to waybar config:
    "custom/dnd": {
      "exec": "~/.config/dunst/scripts/do-not-disturb.sh waybar",
      "interval": 5,
      "return-type": "json",
      "on-click": "~/.config/dunst/scripts/do-not-disturb.sh toggle",
      "on-right-click": "~/.config/dunst/scripts/do-not-disturb.sh rofi"
    }

${BOLD}SCHEDULE (add to crontab -e):%b
  */5 * * * * ~/.config/dunst/scripts/do-not-disturb.sh schedule

HELP
}

# ──────────────────────────────────────────────────────────────────────────────
# 🚀  MAIN DISPATCHER
# ──────────────────────────────────────────────────────────────────────────────

main() {
    _ensure_dirs
    _init_state
    _init_exceptions

    local command="${1:-status}"
    shift || true

    case "${command}" in
        toggle)         cmd_toggle "$@" ;;
        on|enable)      cmd_on "$@" ;;
        off|disable)    cmd_off "$@" ;;
        timer)          cmd_timer "$@" ;;
        focus)          cmd_focus "$@" ;;
        snooze)         cmd_snooze "$@" ;;
        schedule)       cmd_schedule "$@" ;;
        schedule-view)  cmd_show_schedule "$@" ;;
        status)         cmd_status "$@" ;;
        history)        cmd_history "$@" ;;
        allow)          cmd_allow "$@" ;;
        deny)           cmd_deny "$@" ;;
        exceptions)     cmd_exceptions "$@" ;;
        waybar)         cmd_waybar "$@" ;;
        rofi)           cmd_rofi "$@" ;;
        help|--help|-h) cmd_help ;;

        # Internal: called by dunstrc on DUNST_COMMAND_PAUSE
        pause)
            _enable_dnd "dunst" "Dunst command"
            _update_waybar ;;

        # Internal: called by dunstrc on DUNST_COMMAND_RESUME
        resume)
            _disable_dnd "Dunst command"
            _update_waybar ;;

        # Internal: check timer expiry
        check-timer)
            if [[ -f "${DND_TIMER_FILE}" ]] && \
               command -v jq &>/dev/null; then
                local disable_at
                disable_at="$(jq -r '.disable_at // 0' \
                    "${DND_TIMER_FILE}" 2>/dev/null)"
                if (( $(_now_unix) >= disable_at )) && \
                   (( disable_at > 0 )); then
                    cmd_off "Timer expired"
                    rm -f "${DND_TIMER_FILE}"
                fi
            fi ;;

        *)
            printf '%bUnknown command: %s%b\n' "${RED}" "${command}" "${RESET}"
            cmd_help
            exit 1 ;;
    esac
}

main "$@"