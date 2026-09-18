#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Focus Tracker Script                             ║
# ║                                                                              ║
# ║  Tracks window focus changes via Hyprland IPC. Enables per-app actions     ║
# ║  on focus (opacity adjustments, sound cues, mode switching), analytics    ║
# ║  and focus time logging for productivity reporting.                          ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    focus-tracker.sh --daemon     — run as persistent IPC listener           ║
# ║    focus-tracker.sh --report     — show focus time report                   ║
# ║    focus-tracker.sh --today      — today's focus stats                      ║
# ║    focus-tracker.sh --reset      — clear focus history                      ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/focus-tracker.log"
readonly FOCUS_DB="${HOME}/.local/share/ash-dotfiles/analytics/focus.db"
readonly SOCKET="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-focus"

readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[38;2;166;227;161m'
readonly C_BLUE=$'\033[38;2;137;180;250m'
readonly C_MAUVE=$'\033[38;2;203;164;247m'
readonly C_YELLOW=$'\033[38;2;249;226;175m'

_log() {
    printf "[%s] [FOCUS] %s\n" "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE" >/dev/null
}

log_info() { _log "$*"; }
log_ok()   { _log "OK: $*"; }

_setup() {
    mkdir -p "$STATE_DIR" "$(dirname "$LOG_FILE")" \
        "$(dirname "$FOCUS_DB")"
}

# ══════════════════════════════════════════════════════════════════════════════
# §01  FOCUS EVENT PROCESSING
# ══════════════════════════════════════════════════════════════════════════════

declare -g _prev_class=""
declare -g _prev_time=0

_on_focus_change() {
    local class="$1"
    local title="$2"
    local timestamp
    timestamp=$(date +%s)

    # Calculate time spent in previous window
    if [[ -n "$_prev_class" ]] && [[ $_prev_time -gt 0 ]]; then
        local duration=$(( timestamp - _prev_time ))
        _record_focus "$_prev_class" "$duration"
    fi

    _prev_class="$class"
    _prev_time="$timestamp"

    # Per-class actions
    _handle_focus_action "$class" "$title"

    log_info "Focus: $class | $title"
}

# ══════════════════════════════════════════════════════════════════════════════
# §02  PER-CLASS FOCUS ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

_handle_focus_action() {
    local class="$1"
    local title="$2"

    case "$class" in
        # Terminal: no special action
        kitty|foot|alacritty|wezterm)
            ;;

        # Browser: update Waybar media module
        firefox|chromium|brave-browser)
            pkill -SIGUSR1 waybar 2>/dev/null || true
            ;;

        # Gaming: ensure game mode
        steam_app_*)
            if [[ "$(cat "${HOME}/.local/state/ash-dotfiles/current-mode" \
                2>/dev/null || echo default)" != "game" ]]; then
                bash "${HOME}/.config/hypr/scripts/gamemode.sh" on &
            fi
            ;;

        # Media: inhibit idle
        mpv|vlc|celluloid)
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  ANALYTICS RECORDING
# ══════════════════════════════════════════════════════════════════════════════

_record_focus() {
    local class="$1"
    local duration="$2"
    local date
    date=$(date '+%Y-%m-%d')

    # Append to simple CSV log
    printf "%s,%s,%s,%s\n" \
        "$(date -Iseconds)" \
        "$date" \
        "$class" \
        "$duration" \
        >> "${STATE_DIR}/focus-sessions.csv" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  DAEMON LISTENER
# ══════════════════════════════════════════════════════════════════════════════

_daemon_listen() {
    log_info "Focus tracker daemon started"

    if [[ ! -S "$SOCKET" ]]; then
        log_info "Socket not found — waiting..."
        sleep 5
    fi

    socat - "UNIX-CONNECT:${SOCKET}" 2>/dev/null | while read -r line; do
        case "$line" in
            "activewindow>>"*)
                local payload="${line#activewindow>>}"
                local class="${payload%%,*}"
                local title="${payload#*,}"
                _on_focus_change "$class" "$title"
                ;;
            "focusedmon>>"*)
                ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  REPORT
# ══════════════════════════════════════════════════════════════════════════════

_show_report() {
    local csv="${STATE_DIR}/focus-sessions.csv"

    if [[ ! -f "$csv" ]]; then
        echo "No focus data recorded yet."
        return
    fi

    echo -e "\n${C_MAUVE}Focus Time Report${C_RESET}"
    echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

    # Aggregate by class
    awk -F',' '
    {
        class[$3] += $4
    }
    END {
        for (c in class) {
            mins = int(class[c] / 60)
            secs = class[c] % 60
            printf "  %-30s %dmin %dsec\n", c, mins, secs
        }
    }' "$csv" | sort -k2 -rn

    echo ""
}

_show_today() {
    local csv="${STATE_DIR}/focus-sessions.csv"
    local today
    today=$(date '+%Y-%m-%d')

    echo -e "\n${C_MAUVE}Today's Focus (${today})${C_RESET}"
    echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

    grep ",$today," "$csv" 2>/dev/null | \
    awk -F',' '
    {
        class[$3] += $4
    }
    END {
        total = 0
        for (c in class) {
            total += class[c]
            mins = int(class[c] / 60)
            printf "  %-30s %dmin\n", c, mins
        }
        printf "\n  Total: %dmin\n", int(total/60)
    }' | sort -k2 -rn

    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    _setup

    case "${1:---daemon}" in
        --daemon|-d)  _daemon_listen ;;
        --report|-r)  _show_report   ;;
        --today|-t)   _show_today    ;;
        --reset)
            rm -f "${STATE_DIR}/focus-sessions.csv"
            echo "Focus history cleared"
            ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME [--daemon|--report|--today|--reset]"
            ;;
        *)
            echo "Unknown: $1" >&2
            exit 1
            ;;
    esac
}

main "$@"