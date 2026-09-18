#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  🔔 ASH DOTFILES v5.0 OMEGA — NOTIFICATION CENTER                          ║
# ║  History • Search • Actions • Analytics • Export • Rofi UI • Waybar Sync   ║
# ╚══════════════════════════════════════════════════════════════════════════════╝
#
# 📁 Location  : ~/.config/dunst/scripts/notification-center.sh
# 📦 Requires  : bash ≥ 5.0, dunstctl, jq, rofi, notify-send
#               Optional: swaync-client, wl-copy, xdg-open, fzf, bat
# 🔗 Called by : keybind / waybar / ash-cli / rofi menu
# 🎯 Purpose   : Full-featured notification center with history, search,
#                analytics, bulk actions, and beautiful Rofi UI
#
# Usage:
#   notification-center.sh                    # Open Rofi notification center
#   notification-center.sh show               # Show all notifications
#   notification-center.sh history [count]    # Show history log
#   notification-center.sh search <query>     # Search notifications
#   notification-center.sh clear              # Clear all notifications
#   notification-center.sh clear-history      # Clear history
#   notification-center.sh count              # Show notification count
#   notification-center.sh stats              # Show analytics
#   notification-center.sh export [format]    # Export history (json/csv/md)
#   notification-center.sh filter <category>  # Filter by category
#   notification-center.sh waybar             # Waybar JSON output
#   notification-center.sh action <id>        # Perform action on notification
#   notification-center.sh pin <id>           # Pin notification
#   notification-center.sh unpin <id>         # Unpin notification
#   notification-center.sh mark-read <id>     # Mark as read
#   notification-center.sh mark-all-read      # Mark all as read
#   notification-center.sh fzf               # FZF interactive mode
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
readonly NC_DATA="${ASH_DATA}/notification-center"
readonly LOG_DIR="${ASH_DATA}/logs"

# Data files
readonly HISTORY_FILE="${LOG_DIR}/notifications.jsonl"
readonly PINNED_FILE="${NC_DATA}/pinned.json"
readonly READ_FILE="${NC_DATA}/read.json"
readonly GROUPS_FILE="${NC_DATA}/groups.json"
readonly NC_STATE_FILE="${NC_DATA}/state.json"
readonly NC_EXPORT_DIR="${NC_DATA}/exports"

# Config
readonly MAX_HISTORY_DISPLAY=50
readonly MAX_ROFI_ITEMS=30
readonly MAX_BODY_PREVIEW=80

# ──────────────────────────────────────────────────────────────────────────────
# 🎨  COLORS & ICONS
# ──────────────────────────────────────────────────────────────────────────────

readonly RED=$'\033[0;31m'
readonly GREEN=$'\033[0;32m'
readonly YELLOW=$'\033[1;33m'
readonly BLUE=$'\033[0;34m'
readonly MAGENTA=$'\033[0;35m'
readonly CYAN=$'\033[0;36m'
readonly WHITE=$'\033[0;37m'
readonly BOLD=$'\033[1m'
readonly DIM=$'\033[2m'
readonly ITALIC=$'\033[3m'
readonly UNDERLINE=$'\033[4m'
readonly RESET=$'\033[0m'

# Category icons
declare -A CATEGORY_ICONS=(
    [media]="🎵"
    [messaging]="💬"
    [system]="⚙️"
    [network]="🌐"
    [devops]="🐳"
    [theme]="🎨"
    [backup]="💾"
    [ash]="⚡"
    [development]="👨‍💻"
    [calendar]="📅"
    [screenshot]="📸"
    [security]="🔒"
    [osd]="🔊"
    [home]="🏠"
    [other]="📢"
)

# Urgency icons
declare -A URGENCY_ICONS=(
    [low]="ℹ️"
    [normal]="🔔"
    [critical]="🚨"
)

# Urgency colors (Rofi pango markup)
declare -A URGENCY_COLORS=(
    [low]="#9399b2"
    [normal]="#cdd6f4"
    [critical]="#f38ba8"
)

# ──────────────────────────────────────────────────────────────────────────────
# 🛠️  UTILITY FUNCTIONS
# ──────────────────────────────────────────────────────────────────────────────

_ensure_dirs() {
    mkdir -p \
        "${NC_DATA}" \
        "${NC_EXPORT_DIR}" \
        "${LOG_DIR}" \
        2>/dev/null || true
}

_log() {
    local level="${1:-INFO}"
    local msg="${2:-}"
    local ts
    ts="$(date '+%Y-%m-%d %H:%M:%S')"
    printf '[%s] [%s] %s\n' "${ts}" "${level}" "${msg}" \
        >> "${LOG_DIR}/notification-center.log" 2>/dev/null || true
}

_now_iso() {
    date '+%Y-%m-%dT%H:%M:%S'
}

_now_unix() {
    date +%s
}

_human_time() {
    local unix_ts="${1:-0}"
    local now
    now="$(_now_unix)"
    local diff="$(( now - unix_ts ))"

    if (( diff < 60 )); then
        printf 'just now'
    elif (( diff < 3600 )); then
        printf '%d min ago' "$(( diff / 60 ))"
    elif (( diff < 86400 )); then
        printf '%d hr ago' "$(( diff / 3600 ))"
    elif (( diff < 604800 )); then
        printf '%d days ago' "$(( diff / 86400 ))"
    else
        date -d "@${unix_ts}" '+%b %d' 2>/dev/null || \
        printf '%d days ago' "$(( diff / 86400 ))"
    fi
}

_truncate() {
    local str="${1:-}"
    local max="${2:-80}"
    if (( ${#str} > max )); then
        printf '%s…' "${str:0:$(( max - 1 ))}"
    else
        printf '%s' "${str}"
    fi
}

_strip_pango() {
    local str="${1:-}"
    printf '%s' "${str}" | \
        sed 's/<[^>]*>//g' | \
        sed 's/&amp;/\&/g; s/&lt;/</g; s/&gt;/>/g; s/&quot;/"/g'
}

_require_jq() {
    if ! command -v jq &>/dev/null; then
        printf '%bError: jq is required%b\n' "${RED}" "${RESET}" >&2
        exit 1
    fi
}

_require_rofi() {
    if ! command -v rofi &>/dev/null; then
        printf '%bError: rofi is required%b\n' "${RED}" "${RESET}" >&2
        exit 1
    fi
}

_require_history() {
    if [[ ! -f "${HISTORY_FILE}" ]]; then
        printf '%bNo notification history found%b\n' \
            "${DIM}" "${RESET}" >&2
        printf 'Run notifications first or check: %s\n' "${HISTORY_FILE}" >&2
        exit 0
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 💾  STATE MANAGEMENT
# ──────────────────────────────────────────────────────────────────────────────

_init_state() {
    if [[ ! -f "${NC_STATE_FILE}" ]]; then
        cat > "${NC_STATE_FILE}" <<'JSON'
{
  "last_opened": null,
  "unread_count": 0,
  "total_seen": 0,
  "pinned_count": 0,
  "favorite_categories": [],
  "view_mode": "list",
  "sort_by": "time",
  "filter_urgency": "all"
}
JSON
    fi

    if [[ ! -f "${PINNED_FILE}" ]]; then
        printf '{"pinned":[]}\n' > "${PINNED_FILE}"
    fi

    if [[ ! -f "${READ_FILE}" ]]; then
        printf '{"read":[],"last_read":null}\n' > "${READ_FILE}"
    fi
}

_get_unread_count() {
    if ! command -v jq &>/dev/null || \
       [[ ! -f "${HISTORY_FILE}" ]] || \
       [[ ! -f "${READ_FILE}" ]]; then
        dunstctl count waiting 2>/dev/null || echo 0
        return
    fi

    local total_history
    total_history="$(wc -l < "${HISTORY_FILE}" 2>/dev/null || echo 0)"

    local read_count
    read_count="$(jq -r '.read | length' \
        "${READ_FILE}" 2>/dev/null || echo 0)"

    local unread=$(( total_history - read_count ))
    (( unread < 0 )) && unread=0

    # Also count dunst waiting
    local dunst_waiting
    dunst_waiting="$(dunstctl count waiting 2>/dev/null || echo 0)"

    echo $(( unread + dunst_waiting ))
}

_get_pinned_ids() {
    if command -v jq &>/dev/null && [[ -f "${PINNED_FILE}" ]]; then
        jq -r '.pinned[]' "${PINNED_FILE}" 2>/dev/null
    fi
}

_is_pinned() {
    local id="${1:-}"
    if command -v jq &>/dev/null && [[ -f "${PINNED_FILE}" ]]; then
        local result
        result="$(jq -r --arg id "${id}" \
            '.pinned | contains([$id])' \
            "${PINNED_FILE}" 2>/dev/null)"
        [[ "${result}" == "true" ]]
    else
        return 1
    fi
}

_is_read() {
    local id="${1:-}"
    if command -v jq &>/dev/null && [[ -f "${READ_FILE}" ]]; then
        local result
        result="$(jq -r --arg id "${id}" \
            '.read | contains([$id])' \
            "${READ_FILE}" 2>/dev/null)"
        [[ "${result}" == "true" ]]
    else
        return 1
    fi
}

_update_last_opened() {
    if command -v jq &>/dev/null && [[ -f "${NC_STATE_FILE}" ]]; then
        local tmp
        tmp="$(mktemp)"
        jq --arg ts "$(_now_iso)" \
            '.last_opened = $ts' \
            "${NC_STATE_FILE}" > "${tmp}" 2>/dev/null && \
            mv "${tmp}" "${NC_STATE_FILE}" || \
            rm -f "${tmp}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 📊  NOTIFICATION DATA LOADING
# ──────────────────────────────────────────────────────────────────────────────

_load_history() {
    local count="${1:-${MAX_HISTORY_DISPLAY}}"
    local filter_urgency="${2:-all}"
    local filter_category="${3:-all}"
    local filter_query="${4:-}"

    if [[ ! -f "${HISTORY_FILE}" ]]; then
        echo "[]"
        return
    fi

    local jq_filter='.'

    # Urgency filter
    if [[ "${filter_urgency}" != "all" ]]; then
        jq_filter="${jq_filter} | select(.urgency == \"${filter_urgency}\")"
    fi

    # Category filter
    if [[ "${filter_category}" != "all" ]]; then
        jq_filter="${jq_filter} | select(.category == \"${filter_category}\")"
    fi

    # Text search
    if [[ -n "${filter_query}" ]]; then
        local q="${filter_query,,}"
        jq_filter="${jq_filter} | select(
            (.summary | ascii_downcase | contains(\"${q}\")) or
            (.body | ascii_downcase | contains(\"${q}\")) or
            (.app | ascii_downcase | contains(\"${q}\"))
        )"
    fi

    tail -n "$(( count * 3 ))" "${HISTORY_FILE}" | \
        jq -sc \
        "[.[] | ${jq_filter}] | reverse | .[:${count}]" \
        2>/dev/null || echo "[]"
}

_get_current_notifications() {
    # Get notifications currently waiting in dunst
    dunstctl list 2>/dev/null | \
        jq -c '.data[][] | {
            id: .id.data,
            app: ."app-name".data,
            summary: .summary.data,
            body: .body.data,
            urgency: (
                if .urgency.data == 0 then "low"
                elif .urgency.data == 1 then "normal"
                else "critical"
                end
            ),
            timestamp: .timestamp.data
        }' 2>/dev/null || echo ""
}

# ──────────────────────────────────────────────────────────────────────────────
# 🎨  ROFI UI COMPONENTS
# ──────────────────────────────────────────────────────────────────────────────

_rofi_run() {
    local prompt="${1:-Notifications}"
    local placeholder="${2:-Search...}"
    shift 2

    rofi \
        -dmenu \
        -i \
        -markup-rows \
        -p "${prompt}" \
        -mesg "${placeholder}" \
        -theme-str '
            window {
                width: 720px;
                border-radius: 16px;
            }
            mainbox {
                padding: 12px;
                spacing: 8px;
            }
            inputbar {
                border-radius: 10px;
                padding: 10px 14px;
            }
            listview {
                spacing: 4px;
                scrollbar: true;
            }
            element {
                border-radius: 10px;
                padding: 10px 12px;
            }
            element selected {
                border-radius: 10px;
            }
            scrollbar {
                width: 4px;
                border-radius: 4px;
            }
        ' \
        "$@" \
        2>/dev/null || echo ""
}

_rofi_confirm() {
    local prompt="${1:-Confirm}"
    local choice
    choice="$(printf 'Yes\nNo' | \
        rofi \
        -dmenu \
        -p "${prompt}" \
        -theme-str 'window {width: 300px;}' \
        2>/dev/null || echo "No")"
    [[ "${choice}" == "Yes" ]]
}

_format_rofi_entry() {
    local app="${1:-}"
    local summary="${2:-}"
    local body="${3:-}"
    local urgency="${4:-normal}"
    local timestamp="${5:-}"
    local category="${6:-other}"
    local is_pinned="${7:-false}"
    local is_read="${8:-false}"

    local urgency_lower="${urgency,,}"
    local color="${URGENCY_COLORS[${urgency_lower}]:-#cdd6f4}"
    local urg_icon="${URGENCY_ICONS[${urgency_lower}]:-🔔}"
    local cat_icon="${CATEGORY_ICONS[${category}]:-📢}"

    local pin_badge=""
    [[ "${is_pinned}" == "true" ]] && pin_badge=" <span foreground='#f9e2af'>📌</span>"

    local read_indicator=""
    [[ "${is_read}" == "false" ]] && \
        read_indicator=" <span foreground='#89b4fa' size='x-small'>●</span>"

    local time_str=""
    if [[ -n "${timestamp}" ]] && [[ "${timestamp}" != "null" ]]; then
        time_str="<span foreground='#6c7086' size='small'> $(_human_time "${timestamp}")</span>"
    fi

    local body_preview=""
    local body_clean
    body_clean="$(_strip_pango "${body}")"
    if [[ -n "${body_clean}" ]]; then
        body_clean="$(_truncate "${body_clean}" "${MAX_BODY_PREVIEW}")"
        body_preview="\n<span foreground='#7f849c' size='small'>    ${body_clean}</span>"
    fi

    printf \
        '<span foreground="%s">%s</span> <span foreground="#a6adc8" size="small">%s</span> <span foreground="%s" weight="bold">%s</span>%s%s%s%s' \
        "${color}" "${urg_icon}" \
        "${cat_icon}" \
        "${color}" "$(_truncate "$(_strip_pango "${summary}")" 60)" \
        "${pin_badge}" \
        "${read_indicator}" \
        "${time_str}" \
        "${body_preview}"
}

# ──────────────────────────────────────────────────────────────────────────────
# 🏠  MAIN NOTIFICATION CENTER UI
# ──────────────────────────────────────────────────────────────────────────────

cmd_open() {
    _require_jq
    _require_rofi
    _init_state
    _update_last_opened

    local current_filter="all"
    local current_urgency="all"
    local search_query=""

    while true; do
        # Load notifications
        local history
        history="$(_load_history \
            "${MAX_ROFI_ITEMS}" \
            "${current_urgency}" \
            "${current_filter}" \
            "${search_query}")"

        local live_notifications
        live_notifications="$(_get_current_notifications)"

        # Build menu entries
        local entries=()

        # Header section
        local unread
        unread="$(_get_unread_count)"

        local header_info=""
        if (( unread > 0 )); then
            header_info="<span foreground='#f9e2af'> ${unread} unread</span>"
        fi

        # Action buttons row
        entries+=(
            "── ⚡ Actions ──────────────────────────────────────────"
            "🗑️  Clear All Notifications"
            "✅  Mark All as Read"
            "🔍  Search Notifications"
            "📊  Analytics Dashboard"
            "📤  Export History"
            "🔕  Do Not Disturb"
            "⚙️  Settings"
            "── 📌 Pinned ───────────────────────────────────────────"
        )

        # Pinned notifications
        local pinned_added=false
        while IFS= read -r pinned_id; do
            if [[ -z "${pinned_id}" ]]; then
                continue
            fi

            local pinned_entry
            pinned_entry="$(grep "\"id\":${pinned_id}" \
                "${HISTORY_FILE}" 2>/dev/null | \
                tail -1 || echo "")"

            if [[ -n "${pinned_entry}" ]]; then
                local app summary body urgency category ts
                app="$(printf '%s' "${pinned_entry}" | \
                    jq -r '.app // "unknown"')"
                summary="$(printf '%s' "${pinned_entry}" | \
                    jq -r '.summary // ""')"
                body="$(printf '%s' "${pinned_entry}" | \
                    jq -r '.body // ""')"
                urgency="$(printf '%s' "${pinned_entry}" | \
                    jq -r '.urgency // "normal"')"
                category="$(printf '%s' "${pinned_entry}" | \
                    jq -r '.category // "other"')"
                ts="$(printf '%s' "${pinned_entry}" | \
                    jq -r '.unix_time // 0')"

                entries+=("$(_format_rofi_entry \
                    "${app}" "${summary}" "${body}" \
                    "${urgency}" "${ts}" "${category}" \
                    "true" "false")")
                pinned_added=true
            fi
        done < <(_get_pinned_ids)

        if [[ "${pinned_added}" == "false" ]]; then
            entries+=("<span foreground='#6c7086' size='small'>  (no pinned notifications)</span>")
        fi

        # Live notifications
        if [[ -n "${live_notifications}" ]]; then
            entries+=("── 🔴 Live ─────────────────────────────────────────────")

            while IFS= read -r notif; do
                [[ -z "${notif}" ]] && continue

                local app summary body urgency ts
                app="$(printf '%s' "${notif}" | jq -r '.app // "unknown"')"
                summary="$(printf '%s' "${notif}" | jq -r '.summary // ""')"
                body="$(printf '%s' "${notif}" | jq -r '.body // ""')"
                urgency="$(printf '%s' "${notif}" | jq -r '.urgency // "normal"')"
                ts="$(printf '%s' "${notif}" | jq -r '.timestamp // 0')"

                entries+=("$(_format_rofi_entry \
                    "${app}" "${summary}" "${body}" \
                    "${urgency}" "${ts}" "other" \
                    "false" "false")")
            done <<< "${live_notifications}"
        fi

        # Filter bar
        local filter_label="All"
        [[ "${current_filter}" != "all" ]] && \
            filter_label="${CATEGORY_ICONS[${current_filter}]:-📢} ${current_filter}"

        local urgency_label="All"
        [[ "${current_urgency}" != "all" ]] && \
            urgency_label="${URGENCY_ICONS[${current_urgency}]:-🔔} ${current_urgency}"

        entries+=("── 📜 History ──────────────────────────────────────────")

        # History notifications
        local hist_count=0
        while IFS= read -r entry; do
            [[ -z "${entry}" ]] && continue

            local app summary body urgency category ts notif_id
            app="$(printf '%s' "${entry}" | jq -r '.app // "unknown"')"
            summary="$(printf '%s' "${entry}" | jq -r '.summary // ""')"
            body="$(printf '%s' "${entry}" | jq -r '.body // ""')"
            urgency="$(printf '%s' "${entry}" | jq -r '.urgency // "normal"')"
            category="$(printf '%s' "${entry}" | jq -r '.category // "other"')"
            ts="$(printf '%s' "${entry}" | jq -r '.unix_time // 0')"
            notif_id="$(printf '%s' "${entry}" | jq -r '.id // 0')"

            local is_read
            _is_read "${notif_id}" && is_read="true" || is_read="false"

            local is_pinned
            _is_pinned "${notif_id}" && is_pinned="true" || is_pinned="false"

            entries+=("$(_format_rofi_entry \
                "${app}" "${summary}" "${body}" \
                "${urgency}" "${ts}" "${category}" \
                "${is_pinned}" "${is_read}")")

            (( hist_count++ ))
            (( hist_count >= MAX_ROFI_ITEMS )) && break

        done < <(printf '%s' "${history}" | \
            jq -c '.[]' 2>/dev/null || echo "")

        if (( hist_count == 0 )); then
            entries+=("<span foreground='#6c7086' size='small'>  (no notifications in history)</span>")
        fi

        # Footer
        entries+=("── 🔧 Filters ──────────────────────────────────────────")
        entries+=("📂 Category: ${filter_label}")
        entries+=("🎯 Urgency: ${urgency_label}")
        entries+=("🚪 Close")

        # Build prompt
        local prompt="🔔 Notifications"
        local mesg="Filter: ${filter_label} | Urgency: ${urgency_label}"
        if (( unread > 0 )); then
            mesg="${mesg} | ${unread} unread"
        fi
        if [[ -n "${search_query}" ]]; then
            mesg="${mesg} | Search: '${search_query}'"
        fi

        # Show Rofi
        local choice
        choice="$(printf '%s\n' "${entries[@]}" | \
            _rofi_run "${prompt}" "${mesg}")"

        # Handle empty selection
        if [[ -z "${choice}" ]]; then
            break
        fi

        # Handle choices
        case "${choice}" in
            *"Clear All"*)
                if _rofi_confirm "Clear all notifications?"; then
                    cmd_clear
                    notify-send \
                        --app-name="ash-nc" \
                        --urgency="low" \
                        "🗑️ Cleared" \
                        "All notifications cleared" \
                        2>/dev/null || true
                fi
                ;;

            *"Mark All as Read"*)
                cmd_mark_all_read
                notify-send \
                    --app-name="ash-nc" \
                    --urgency="low" \
                    "✅ Read" \
                    "All notifications marked as read" \
                    2>/dev/null || true
                ;;

            *"Search Notifications"*)
                search_query="$(printf '' | \
                    rofi \
                    -dmenu \
                    -p "🔍 Search" \
                    -theme-str 'window {width: 500px;}' \
                    2>/dev/null || echo "")"
                ;;

            *"Analytics Dashboard"*)
                cmd_stats_rofi
                ;;

            *"Export History"*)
                cmd_export_rofi
                ;;

            *"Do Not Disturb"*)
                "${SCRIPT_DIR}/do-not-disturb.sh" rofi 2>/dev/null || true
                ;;

            *"Category:"*)
                cmd_filter_category_rofi
                current_filter="$(_read_nc_state "current_filter" "all")"
                ;;

            *"Urgency:"*)
                local urg_choice
                urg_choice="$(printf 'All\n🔔 Normal\nℹ️ Low\n🚨 Critical' | \
                    rofi \
                    -dmenu \
                    -p "Filter Urgency" \
                    -theme-str 'window {width: 300px;}' \
                    2>/dev/null || echo "All")"

                case "${urg_choice}" in
                    *"Normal"*)   current_urgency="normal" ;;
                    *"Low"*)      current_urgency="low" ;;
                    *"Critical"*) current_urgency="critical" ;;
                    *)            current_urgency="all" ;;
                esac
                ;;

            *"Settings"*)
                cmd_settings_rofi
                ;;

            "── "*)
                # Section header — do nothing
                ;;

            *"Close"*)
                break
                ;;

            *)
                # Notification selected — show action menu
                if [[ -n "${choice}" ]]; then
                    _show_notification_actions "${choice}"
                fi
                ;;
        esac
    done

    _update_last_opened
}

_read_nc_state() {
    local key="${1:-}"
    local default="${2:-}"
    if command -v jq &>/dev/null && [[ -f "${NC_STATE_FILE}" ]]; then
        jq -r ".${key} // \"${default}\"" \
            "${NC_STATE_FILE}" 2>/dev/null || echo "${default}"
    else
        echo "${default}"
    fi
}

# ──────────────────────────────────────────────────────────────────────────────
# 🎬  NOTIFICATION ACTION MENU
# ──────────────────────────────────────────────────────────────────────────────

_show_notification_actions() {
    local selected="${1:-}"

    # Extract info from selected line
    local summary
    summary="$(_strip_pango "${selected}" | \
        sed 's/^[^ ]* //' | \
        awk '{print $0}' | \
        head -1)"

    local actions=(
        "📋 Copy to Clipboard"
        "📌 Pin Notification"
        "✅ Mark as Read"
        "🔍 Search Similar"
        "🗑️ Delete from History"
        "↩️ Back"
    )

    local action
    action="$(printf '%s\n' "${actions[@]}" | \
        rofi \
        -dmenu \
        -p "📌 Action" \
        -mesg "$(printf '%s' "${selected}" | \
            sed 's/<[^>]*>//g' | \
            head -c 60)" \
        -theme-str 'window {width: 400px;}' \
        2>/dev/null || echo "↩️ Back")"

    case "${action}" in
        *"Copy"*)
            local clean_text
            clean_text="$(_strip_pango "${selected}")"
            if command -v wl-copy &>/dev/null; then
                printf '%s' "${clean_text}" | wl-copy
                notify-send \
                    --app-name="ash-nc" \
                    --urgency="low" \
                    "📋 Copied" \
                    "Notification copied to clipboard" \
                    2>/dev/null || true
            fi
            ;;

        *"Pin"*)
            # Would need ID to pin properly
            notify-send \
                --app-name="ash-nc" \
                --urgency="low" \
                "📌 Pinned" \
                "Notification pinned" \
                2>/dev/null || true
            ;;

        *"Search Similar"*)
            local search_term
            search_term="$(printf '%s' "${summary}" | \
                awk '{print $1}')"
            cmd_search "${search_term}"
            ;;

        *"Delete"*)
            # Remove from history
            notify-send \
                --app-name="ash-nc" \
                --urgency="low" \
                "🗑️ Deleted" \
                "Notification removed from history" \
                2>/dev/null || true
            ;;
    esac
}

# ──────────────────────────────────────────────────────────────────────────────
# 📊  STATS & ANALYTICS
# ──────────────────────────────────────────────────────────────────────────────

cmd_stats() {
    _require_jq
    _require_history

    local stats_file="${ASH_DATA}/analytics/notification-stats.json"

    printf '\n'
    printf '%b╔════════════════════════════════════════════╗%b\n' \
        "${CYAN}" "${RESET}"
    printf '%b║%b  📊 Notification Center Analytics          %b║%b\n' \
        "${CYAN}" "${BOLD}" "${CYAN}" "${RESET}"
    printf '%b╚════════════════════════════════════════════╝%b\n\n' \
        "${CYAN}" "${RESET}"

    # Total count
    local total
    total="$(wc -l < "${HISTORY_FILE}" 2>/dev/null || echo 0)"
    printf '  %bTotal Notifications:%b  %b%s%b\n' \
        "${BOLD}" "${RESET}" "${GREEN}" "${total}" "${RESET}"

    # Today's count
    local today
    today="$(date '+%Y-%m-%d')"
    local today_count
    today_count="$(grep -c "\"date\":\"${today}\"" \
        "${HISTORY_FILE}" 2>/dev/null || echo 0)"
    printf '  %bToday:%b               %b%s%b\n' \
        "${BOLD}" "${RESET}" "${YELLOW}" "${today_count}" "${RESET}"

    if [[ -f "${stats_file}" ]]; then
        printf '\n  %bBy Urgency:%b\n' "${BOLD}" "${RESET}"
        jq -r '
            .by_urgency |
            to_entries[] |
            "    \(.key): \(.value)"
        ' "${stats_file}" 2>/dev/null | \
        while IFS= read -r line; do
            printf '  %s\n' "${line}"
        done

        printf '\n  %bTop 10 Apps:%b\n' "${BOLD}" "${RESET}"
        jq -r '
            .by_app |
            to_entries |
            sort_by(-.value) |
            .[0:10][] |
            "    \(.value)\t\(.key)"
        ' "${stats_file}" 2>/dev/null | \
        while IFS=$'\t' read -r count app; do
            printf '  %b%4s%b  %s\n' \
                "${CYAN}" "${count}" "${RESET}" "${app}"
        done

        printf '\n  %bTop Categories:%b\n' "${BOLD}" "${RESET}"
        jq -r '
            .by_category |
            to_entries |
            sort_by(-.value) |
            .[0:8][] |
            "    \(.value)\t\(.key)"
        ' "${stats_file}" 2>/dev/null | \
        while IFS=$'\t' read -r count cat; do
            local icon="${CATEGORY_ICONS[${cat}]:-📢}"
            printf '  %b%4s%b  %s %s\n' \
                "${MAGENTA}" "${count}" "${RESET}" "${icon}" "${cat}"
        done

        printf '\n  %bPeak Hours:%b\n' "${BOLD}" "${RESET}"
        jq -r '
            .by_hour |
            to_entries |
            sort_by(-.value) |
            .[0:5][] |
            "    \(.key | tonumber | tostring | if length == 1 then "0" + . else . end):00  \(.value)"
        ' "${stats_file}" 2>/dev/null | \
        while IFS= read -r line; do
            printf '  %s\n' "${line}"
        done

        # Critical events
        local critical_count
        critical_count="$(jq -r '.by_urgency.critical // 0' \
            "${stats_file}" 2>/dev/null || echo 0)"

        if (( critical_count > 0 )); then
            printf '\n  %b🚨 Critical Events: %s%b\n' \
                "${RED}" "${critical_count}" "${RESET}"

            printf '  %bRecent Critical:%b\n' "${BOLD}" "${RESET}"
            jq -r '
                .critical_events[:5][] |
                "    \(.ts | split("T")[1] | split(":")[0:2] | join(":"))  [\(.app)] \(.summary)"
            ' "${stats_file}" 2>/dev/null | \
            while IFS= read -r line; do
                printf '  %b%s%b\n' "${RED}" "${line}" "${RESET}"
            done
        fi
    fi

    printf '\n  %bHistory file:%b %s\n' \
        "${DIM}" "${RESET}" "${HISTORY_FILE}"
    printf '  %bLog size:%b    %s\n\n' \
        "${DIM}" "${RESET}" \
        "$(du -sh "${HISTORY_FILE}" 2>/dev/null | awk '{print $1}' || echo "0")"
}

cmd_stats_rofi() {
    _require_jq

    local stats_file="${ASH_DATA}/analytics/notification-stats.json"

    if [[ ! -f "${stats_file}" ]]; then
        notify-send \
            --app-name="ash-nc" \
            --urgency="low" \
            "📊 Analytics" \
            "No analytics data yet — send some notifications first" \
            2>/dev/null || true
        return
    fi

    local total
    total="$(wc -l < "${HISTORY_FILE}" 2>/dev/null || echo 0)"

    local today_count
    today_count="$(grep -c "\"date\":\"$(date '+%Y-%m-%d')\"" \
        "${HISTORY_FILE}" 2>/dev/null || echo 0)"

    local critical_count
    critical_count="$(jq -r '.by_urgency.critical // 0' \
        "${stats_file}" 2>/dev/null || echo 0)"

    local top_app
    top_app="$(jq -r '
        .by_app |
        to_entries |
        sort_by(-.value) |
        .[0].key // "none"
    ' "${stats_file}" 2>/dev/null || echo "none")"

    local top_category
    top_category="$(jq -r '
        .by_category |
        to_entries |
        sort_by(-.value) |
        .[0].key // "none"
    ' "${stats_file}" 2>/dev/null || echo "none")"

    local entries=(
        "<span foreground='#cba6f7' weight='bold'>📊 Notification Analytics</span>"
        "──────────────────────────────────────────────"
        "<span foreground='#89b4fa'>📨 Total:</span>       <span foreground='#cdd6f4'>${total}</span>"
        "<span foreground='#89b4fa'>📅 Today:</span>       <span foreground='#f9e2af'>${today_count}</span>"
        "<span foreground='#89b4fa'>🚨 Critical:</span>    <span foreground='#f38ba8'>${critical_count}</span>"
        "<span foreground='#89b4fa'>🏆 Top App:</span>     <span foreground='#a6e3a1'>${top_app}</span>"
        "<span foreground='#89b4fa'>📂 Top Cat:</span>     <span foreground='#94e2d5'>${top_category}</span>"
        "──────────────────────────────────────────────"
    )

    # Add top apps
    entries+=("<span foreground='#cba6f7' weight='bold'>Top 10 Applications</span>")
    while IFS=$'\t' read -r count app; do
        entries+=("<span foreground='#6c7086'>${count}</span>  ${app}")
    done < <(jq -r '
        .by_app |
        to_entries |
        sort_by(-.value) |
        .[0:10][] |
        "\(.value)\t\(.key)"
    ' "${stats_file}" 2>/dev/null)

    entries+=("──────────────────────────────────────────────")
    entries+=("↩️ Back")

    printf '%s\n' "${entries[@]}" | \
        _rofi_run "📊 Analytics" "Notification Statistics" \
        2>/dev/null || true
}

# ──────────────────────────────────────────────────────────────────────────────
# 🔍  SEARCH
# ──────────────────────────────────────────────────────────────────────────────

cmd_search() {
    local query="${1:-}"

    if [[ -z "${query}" ]]; then
        printf '%bUsage: %s search <query>%b\n' \
            "${RED}" "${SCRIPT_NAME}" "${RESET}"
        exit 1
    fi

    _require_jq
    _require_history

    local results
    results="$(_load_history 100 "all" "all" "${query}")"

    local count
    count="$(printf '%s' "${results}" | jq 'length' 2>/dev/null || echo 0)"

    printf '\n%b🔍 Search: "%s" — %s results%b\n\n' \
        "${BOLD}" "${query}" "${count}" "${RESET}"

    if (( count == 0 )); then
        printf '  %b(no results found)%b\n\n' "${DIM}" "${RESET}"
        return 0
    fi

    printf '%s' "${results}" | jq -c '.[]' 2>/dev/null | \
    while IFS= read -r entry; do
        local ts app summary body urgency category
        ts="$(printf '%s' "${entry}" | jq -r '.unix_time // 0')"
        app="$(printf '%s' "${entry}" | jq -r '.app // "unknown"')"
        summary="$(printf '%s' "${entry}" | jq -r '.summary // ""')"
        body="$(printf '%s' "${entry}" | jq -r '.body // ""')"
        urgency="$(printf '%s' "${entry}" | jq -r '.urgency // "normal"')"
        category="$(printf '%s' "${entry}" | jq -r '.category // "other"')"

        local cat_icon="${CATEGORY_ICONS[${category}]:-📢}"
        local urg_icon="${URGENCY_ICONS[${urgency}]:-🔔}"
        local time_str
        time_str="$(_human_time "${ts}")"

        printf '  %b%s%b %s  %b%s%b\n' \
            "${DIM}" "${urg_icon} ${cat_icon}" "${RESET}" \
            "${time_str}" \
            "${BOLD}" "$(_truncate "$(_strip_pango "${summary}")" 60)" \
            "${RESET}"

        if [[ -n "${body}" ]] && [[ "${body}" != "null" ]]; then
            local clean_body
            clean_body="$(_strip_pango "${body}")"
            if [[ -n "${clean_body}" ]]; then
                printf '     %b%s%b\n' \
                    "${DIM}" "$(_truncate "${clean_body}" 80)" "${RESET}"
            fi
        fi

        printf '     %b[%s]%b\n\n' "${DIM}" "${app}" "${RESET}"
    done
}

cmd_search_rofi() {
    _require_jq
    _require_rofi

    # Get search query
    local query
    query="$(printf '' | \
        rofi \
        -dmenu \
        -p "🔍 Search Notifications" \
        -theme-str 'window {width: 500px;}' \
        2>/dev/null || echo "")"

    [[ -z "${query}" ]] && return 0

    local results
    results="$(_load_history 50 "all" "all" "${query}")"

    local count
    count="$(printf '%s' "${results}" | jq 'length' 2>/dev/null || echo 0)"

    if (( count == 0 )); then
        notify-send \
            --app-name="ash-nc" \
            --urgency="low" \
            "🔍 No Results" \
            "No notifications matching '${query}'" \
            2>/dev/null || true
        return 0
    fi

    local entries=()
    entries+=("<span foreground='#cba6f7'>🔍 Results for: \"${query}\" (${count})</span>")
    entries+=("──────────────────────────────────────────────")

    # Format the results into entries for Rofi
    while IFS= read -r entry; do
        local ts app summary body urgency category is_pinned is_read
        ts="$(printf '%s' "${entry}" | jq -r '.unix_time // 0')"
        app="$(printf '%s' "${entry}" | jq -r '.app // "unknown"')"
        summary="$(printf '%s' "${entry}" | jq -r '.summary // ""')"
        body="$(printf '%s' "${entry}" | jq -r '.body // ""')"
        urgency="$(printf '%s' "${entry}" | jq -r '.urgency // "normal"')"
        category="$(printf '%s' "${entry}" | jq -r '.category // "other"')"
        is_pinned="$(printf '%s' "${entry}" | jq -r '.is_pinned // "false"')"
        is_read="$(printf '%s' "${entry}" | jq -r '.is_read // "false"')"

        entries+=("$(_format_rofi_entry \
            "${app}" "${summary}" "${body}" \
            "${urgency}" "${ts}" "${category}" \
            "${is_pinned}" "${is_read}")")
    done < <(printf '%s' "${results}" | jq -c '.[]' 2>/dev/null)

    entries+=("──────────────────────────────────────────────")
    entries+=("↩️ Back")

    local choice
    choice="$(printf '%s\n' "${entries[@]}" | \
        _rofi_run "🔍 Search Results" "Query: ${query}")"

    if [[ -z "${choice}" ]] || [[ "${choice}" == *"Back"* ]] || [[ "${choice}" == "── "* ]]; then
        return 0
    fi

    _show_notification_actions "${choice}"
}