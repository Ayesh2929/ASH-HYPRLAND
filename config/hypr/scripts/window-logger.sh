#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Window Event Logger                              ║
# ║                                                                              ║
# ║  Logs all window lifecycle events from Hyprland IPC: open, close, move,   ║
# ║  resize, workspace change, title change. Useful for debugging window       ║
# ║  rules, building analytics, and session reconstruction.                     ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    window-logger.sh --daemon     — run as persistent event logger           ║
# ║    window-logger.sh --tail       — tail the window log                      ║
# ║    window-logger.sh --search CLS — search log for class                     ║
# ║    window-logger.sh --stats      — show window open statistics              ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/window-events.log"
readonly STATS_FILE="${HOME}/.local/state/ash-dotfiles/logs/window-stats.csv"
readonly SOCKET="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

readonly C_RESET='\033[0m'
readonly C_GREEN='\033[38;2;166;227;161m'
readonly C_BLUE='\033[38;2;137;180;250m'
readonly C_YELLOW='\033[38;2;249;226;175m'
readonly C_RED='\033[38;2;243;139;168m'
readonly C_MAUVE='\033[38;2;203;164;247m'
readonly C_GREY='\033[38;2;127;132;156m'

_log_event() {
    local event="$1"
    local data="$2"
    printf "[%s] %-20s %s\n" \
        "$(date '+%Y-%m-%dT%H:%M:%S')" \
        "$event" \
        "$data" \
        >> "$LOG_FILE"
}

_log_stat() {
    local class="$1"
    local event="$2"
    printf "%s,%s,%s\n" \
        "$(date '+%Y-%m-%d')" \
        "$event" \
        "$class" \
        >> "$STATS_FILE" 2>/dev/null || true
}

_setup() {
    mkdir -p "$(dirname "$LOG_FILE")" "$(dirname "$STATS_FILE")"
    touch "$LOG_FILE" "$STATS_FILE" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §01  EVENT HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

_on_window_open() {
    local addr="$1" ws="$2" class="$3" title="$4"
    _log_event "OPEN" "addr=$addr ws=$ws class=$class title=${title:0:60}"
    _log_stat "$class" "open"
}

_on_window_close() {
    local addr="$1"
    # Look up class from addr in recent log
    local class
    class=$(grep "$addr" "$LOG_FILE" 2>/dev/null | \
        grep "OPEN" | tail -1 | \
        grep -oP 'class=\K\S+' 2>/dev/null || echo "unknown")
    _log_event "CLOSE" "addr=$addr class=$class"
    _log_stat "$class" "close"
}

_on_window_move() {
    local addr="$1" ws="$2"
    _log_event "MOVE_WS" "addr=$addr ws=$ws"
}

_on_window_float() {
    local addr="$1" floating="$2"
    _log_event "FLOAT" "addr=$addr floating=$floating"
}

_on_window_title() {
    local addr="$1"
    local title
    title=$(hyprctl -j clients 2>/dev/null | \
        jq -r ".[] | select(.address == \"$addr\") | .title" \
        2>/dev/null | head -c 80 || echo "unknown")
    _log_event "TITLE" "addr=$addr title=$title"
}

_on_fullscreen() {
    local state="$1"
    local class
    class=$(hyprctl -j activewindow 2>/dev/null | jq -r '.class' 2>/dev/null || echo "unknown")
    _log_event "FULLSCREEN" "state=$state class=$class"
}

_on_urgent() {
    local addr="$1"
    _log_event "URGENT" "addr=$addr"
}

# ══════════════════════════════════════════════════════════════════════════════
# §02  DAEMON LISTENER
# ══════════════════════════════════════════════════════════════════════════════

_daemon_listen() {
    echo -e "${C_BLUE}[WINDOW-LOGGER]${C_RESET} Starting daemon..."
    echo -e "${C_GREY}Log: $LOG_FILE${C_RESET}"

    [[ ! -S "$SOCKET" ]] && { sleep 3; }

    socat - "UNIX-CONNECT:${SOCKET}" 2>/dev/null | while read -r line; do
        case "$line" in
            openwindow>>*)
                local payload="${line#openwindow>>}"
                IFS=',' read -r addr ws class title <<< "$payload"
                _on_window_open "$addr" "$ws" "$class" "$title"
                ;;
            closewindow>>*)
                local addr="${line#closewindow>>}"
                _on_window_close "$addr"
                ;;
            movewindow>>*)
                local payload="${line#movewindow>>}"
                IFS=',' read -r addr ws <<< "$payload"
                _on_window_move "$addr" "$ws"
                ;;
            windowtitle>>*)
                local addr="${line#windowtitle>>}"
                _on_window_title "$addr"
                ;;
            changefloatingmode>>*)
                local payload="${line#changefloatingmode>>}"
                IFS=',' read -r addr floating <<< "$payload"
                _on_window_float "$addr" "$floating"
                ;;
            fullscreen>>*)
                local state="${line#fullscreen>>}"
                _on_fullscreen "$state"
                ;;
            urgent>>*)
                local addr="${line#urgent>>}"
                _on_urgent "$addr"
                ;;
        esac
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  TAIL & SEARCH
# ══════════════════════════════════════════════════════════════════════════════

_tail_log() {
    echo -e "${C_MAUVE}Window Event Log — Live${C_RESET}"
    tail -f "$LOG_FILE" 2>/dev/null | while IFS= read -r line; do
        # Color-code event types
        echo "$line" | sed \
            -e "s/OPEN/${C_GREEN}OPEN${C_RESET}/" \
            -e "s/CLOSE/${C_RED}CLOSE${C_RESET}/" \
            -e "s/MOVE_WS/${C_BLUE}MOVE_WS${C_RESET}/" \
            -e "s/FULLSCREEN/${C_YELLOW}FULLSCREEN${C_RESET}/" \
            -e "s/URGENT/${C_RED}URGENT${C_RESET}/"
    done
}

_search_log() {
    local query="${1:-}"
    [[ -z "$query" ]] && { echo "Usage: search CLASS"; exit 1; }

    echo -e "${C_MAUVE}Events for: $query${C_RESET}"
    grep -i "$query" "$LOG_FILE" 2>/dev/null | tail -50 || \
        echo "No events found for: $query"
}

_show_stats() {
    echo -e "\n${C_MAUVE}Window Statistics${C_RESET}"
    echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

    echo -e "\n${C_GREEN}Most opened apps:${C_RESET}"
    grep ",open," "$STATS_FILE" 2>/dev/null | \
        awk -F',' '{print $3}' | \
        sort | uniq -c | sort -rn | head -10 | \
        awk '{printf "  %-5s %s\n", $1, $2}'

    echo -e "\n${C_YELLOW}Today's openings:${C_RESET}"
    local today
    today=$(date '+%Y-%m-%d')
    grep "^$today,open," "$STATS_FILE" 2>/dev/null | wc -l | \
        xargs -I{} echo "  {} windows opened today"

    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    _setup

    case "${1:---daemon}" in
        --daemon|-d)   _daemon_listen        ;;
        --tail|-t)     _tail_log             ;;
        --search|-s)   _search_log "${2:-}"  ;;
        --stats)       _show_stats           ;;
        --clear)
            > "$LOG_FILE"
            > "$STATS_FILE"
            echo "Window logs cleared"
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [--daemon|--tail|--search CLASS|--stats|--clear]"
            ;;
        *)
            echo "Unknown: $1" >&2; exit 1
            ;;
    esac
}

main "$@"