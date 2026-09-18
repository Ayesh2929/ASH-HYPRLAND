#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Gesture Handler Script                           ║
# ║                                                                              ║
# ║  Processes touchpad/touchscreen gesture events from Hyprland IPC and       ║
# ║  executes mapped actions. Extends native gesture support with custom       ║
# ║  multi-finger combos, edge swipes, hold gestures and temporal sequences.   ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    gesture-handler.sh --daemon   — run as persistent IPC listener           ║
# ║    gesture-handler.sh --test     — test gesture detection                   ║
# ║    gesture-handler.sh --list     — list configured gestures                 ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/gesture-handler.log"
readonly SOCKET="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"
readonly CONFIG="${HOME}/.config/ash-dotfiles/ash-cli/data/ash.conf"

readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[38;2;166;227;161m'
readonly C_BLUE=$'\033[38;2;137;180;250m'
readonly C_YELLOW=$'\033[38;2;249;226;175m'
readonly C_MAUVE=$'\033[38;2;203;164;247m'

_log() {
    printf "[%s] [GESTURE] %s\n" "$(date '+%Y-%m-%dT%H:%M:%S')" "$*" \
        | tee -a "$LOG_FILE" >/dev/null
}

log_info() { _log "$*"; }
log_ok()   { _log "OK: $*"; }
log_warn() { _log "WARN: $*"; echo -e "${C_YELLOW}[GESTURE]${C_RESET} $*" >&2; }

_notify() {
    notify-send "ASH Gesture" "$1" \
        --urgency=low \
        --expire-time=1500 \
        --hint=string:x-dunst-stack-tag:gesture \
        2>/dev/null || true
}

_hyprctl() {
    hyprctl "$@" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §01  GESTURE ACTION MAP
# ══════════════════════════════════════════════════════════════════════════════

# Actions executed when each gesture fires
# These supplement the native Hyprland gesture binds in gestures.conf

_action_swipe_left_3() {
    # 3-finger swipe left → next workspace
    _hyprctl dispatch workspace +1
    log_info "Swipe left 3: workspace +1"
}

_action_swipe_right_3() {
    # 3-finger swipe right → previous workspace
    _hyprctl dispatch workspace -1
    log_info "Swipe right 3: workspace -1"
}

_action_swipe_up_3() {
    # 3-finger swipe up → toggle overview
    _hyprctl dispatch hyprexpo:expo toggle 2>/dev/null || \
        _hyprctl dispatch overview:toggle 2>/dev/null || true
    log_info "Swipe up 3: overview"
}

_action_swipe_down_3() {
    # 3-finger swipe down → scratchpad
    _hyprctl dispatch togglespecialworkspace scratch
    log_info "Swipe down 3: scratch"
}

_action_swipe_left_4() {
    # 4-finger swipe left → move window to next workspace
    _hyprctl dispatch movetoworkspace +1
    log_info "Swipe left 4: movewindow +1"
}

_action_swipe_right_4() {
    # 4-finger swipe right → move window to prev workspace
    _hyprctl dispatch movetoworkspace -1
    log_info "Swipe right 4: movewindow -1"
}

_action_swipe_up_4() {
    # 4-finger swipe up → fullscreen
    _hyprctl dispatch fullscreen 0
    log_info "Swipe up 4: fullscreen"
}

_action_swipe_down_4() {
    # 4-finger swipe down → notification center
    swaync-client --toggle-panel 2>/dev/null || true
    log_info "Swipe down 4: notification center"
}

_action_edge_left() {
    # Edge swipe from left → launcher
    rofi -show drun 2>/dev/null &
    log_info "Edge left: launcher"
}

_action_edge_right() {
    # Edge swipe from right → notification center
    swaync-client --toggle-panel 2>/dev/null || true
    log_info "Edge right: notification panel"
}

_action_edge_top() {
    # Edge swipe from top → quick settings
    swaync-client --toggle-panel 2>/dev/null || true
    log_info "Edge top: quick settings"
}

_action_edge_bottom() {
    # Edge swipe from bottom → app launcher / dock
    rofi -show drun 2>/dev/null &
    log_info "Edge bottom: launcher"
}

_action_pinch_in() {
    # Pinch in → toggle floating
    _hyprctl dispatch togglefloating
    log_info "Pinch in: togglefloating"
}

_action_pinch_out() {
    # Pinch out → maximize
    _hyprctl dispatch fullscreen 1
    log_info "Pinch out: maximize"
}

# ══════════════════════════════════════════════════════════════════════════════
# §02  GESTURE EVENT PARSER
# ══════════════════════════════════════════════════════════════════════════════

_parse_gesture() {
    local event="$1"

    # IPC gesture events from hyprgrass plugin:
    # gesture>>swipe:3:l   gesture>>swipe:3:r   gesture>>swipe:3:u   gesture>>swipe:3:d
    # gesture>>swipe:4:l   gesture>>swipe:4:r   gesture>>swipe:4:u   gesture>>swipe:4:d
    # gesture>>edge:l>r    gesture>>edge:r>l    gesture>>edge:u>d    gesture>>edge:d>u
    # gesture>>pinch:in    gesture>>pinch:out

    case "$event" in
        # ── 3-finger swipes ───────────────────────────────────────────────────
        "swipe:3:l"|"swipe:3:left")   _action_swipe_left_3  ;;
        "swipe:3:r"|"swipe:3:right")  _action_swipe_right_3 ;;
        "swipe:3:u"|"swipe:3:up")     _action_swipe_up_3    ;;
        "swipe:3:d"|"swipe:3:down")   _action_swipe_down_3  ;;

        # ── 4-finger swipes ───────────────────────────────────────────────────
        "swipe:4:l"|"swipe:4:left")   _action_swipe_left_4  ;;
        "swipe:4:r"|"swipe:4:right")  _action_swipe_right_4 ;;
        "swipe:4:u"|"swipe:4:up")     _action_swipe_up_4    ;;
        "swipe:4:d"|"swipe:4:down")   _action_swipe_down_4  ;;

        # ── Edge swipes ───────────────────────────────────────────────────────
        "edge:l>r"|"edge:left")       _action_edge_left     ;;
        "edge:r>l"|"edge:right")      _action_edge_right    ;;
        "edge:u>d"|"edge:top")        _action_edge_top      ;;
        "edge:d>u"|"edge:bottom")     _action_edge_bottom   ;;

        # ── Pinch ─────────────────────────────────────────────────────────────
        "pinch:in")                   _action_pinch_in      ;;
        "pinch:out")                  _action_pinch_out     ;;

        *)
            log_warn "Unknown gesture: $event"
            ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  DAEMON LISTENER
# ══════════════════════════════════════════════════════════════════════════════

_daemon_listen() {
    echo -e "${C_BLUE}[GESTURE-HANDLER]${C_RESET} Daemon started"

    [[ ! -S "$SOCKET" ]] && {
        log_warn "IPC socket not found — waiting 5s..."
        sleep 5
    }

    socat - "UNIX-CONNECT:${SOCKET}" 2>/dev/null | while read -r line; do
        # hyprgrass emits: gesture>>TYPE
        if [[ "$line" == gesture\>\>* ]]; then
            local gesture="${line#gesture>>}"
            _parse_gesture "$gesture"
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  TEST MODE
# ══════════════════════════════════════════════════════════════════════════════

_test_gestures() {
    echo -e "\n${C_MAUVE}Gesture Handler — Test Mode${C_RESET}"
    echo -e "${C_GREY}Execute gestures on your touchpad. Events will show here.${C_RESET}"
    echo -e "${C_GREY}Press Ctrl+C to exit.${C_RESET}\n"

    [[ ! -S "$SOCKET" ]] && {
        echo "Hyprland IPC socket not available"
        exit 1
    }

    socat - "UNIX-CONNECT:${SOCKET}" 2>/dev/null | while read -r line; do
        if [[ "$line" == gesture\>\>* ]]; then
            local gesture="${line#gesture>>}"
            echo -e "${C_GREEN}GESTURE:${C_RESET} $gesture"
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  LIST CONFIGURED GESTURES
# ══════════════════════════════════════════════════════════════════════════════

_list_gestures() {
    echo -e "\n${C_MAUVE}Configured Gestures${C_RESET}"
    echo -e "${C_BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${C_RESET}"

    printf "${C_GREY}%-25s${C_RESET}  %s\n" "GESTURE" "ACTION"
    printf "${C_GREY}%-25s${C_RESET}  %s\n" "───────────────────────" "──────────────────────"

    printf "%-25s  %s\n" "3-finger left"    "→ next workspace"
    printf "%-25s  %s\n" "3-finger right"   "→ prev workspace"
    printf "%-25s  %s\n" "3-finger up"      "→ overview (hyprexpo)"
    printf "%-25s  %s\n" "3-finger down"    "→ scratchpad terminal"
    printf "%-25s  %s\n" "4-finger left"    "→ move window +1 ws"
    printf "%-25s  %s\n" "4-finger right"   "→ move window -1 ws"
    printf "%-25s  %s\n" "4-finger up"      "→ fullscreen"
    printf "%-25s  %s\n" "4-finger down"    "→ notification center"
    printf "%-25s  %s\n" "edge: left→right" "→ app launcher (rofi)"
    printf "%-25s  %s\n" "edge: right→left" "→ notification panel"
    printf "%-25s  %s\n" "edge: top→down"   "→ quick settings"
    printf "%-25s  %s\n" "edge: bottom→up"  "→ app launcher"
    printf "%-25s  %s\n" "pinch in"         "→ toggle floating"
    printf "%-25s  %s\n" "pinch out"        "→ maximize window"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    case "${1:---daemon}" in
        --daemon|-d)  _daemon_listen ;;
        --test|-t)    _test_gestures ;;
        --list|-l)    _list_gestures ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME [--daemon|--test|--list]"
            ;;
        *)
            log_warn "Unknown: $1"
            exit 1
            ;;
    esac
}

main "$@"