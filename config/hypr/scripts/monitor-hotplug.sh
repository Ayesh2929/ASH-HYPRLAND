#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Monitor Hotplug Handler                          ║
# ║                                                                              ║
# ║  Responds to monitor connect/disconnect events from Hyprland IPC.          ║
# ║  Applies saved layout profiles, adjusts workspace distribution,            ║
# ║  sets wallpaper per-monitor, and notifies user of changes.                 ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    monitor-hotplug.sh --daemon     — run as persistent IPC listener         ║
# ║    monitor-hotplug.sh --once       — handle current monitor state once      ║
# ║    monitor-hotplug.sh --list       — list connected monitors                ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/monitor-hotplug.log"
readonly PROFILE_DIR="${HOME}/.config/kanshi"
readonly WALLPAPER_CACHE="${HOME}/.cache/ash-dotfiles/wallpapers"
readonly SOCKET="${XDG_RUNTIME_DIR:-/tmp}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket2.sock"

# ── Colors ────────────────────────────────────────────────────────────────────
readonly C_RESET=$'\033[0m'
readonly C_GREEN=$'\033[38;2;166;227;161m'
readonly C_YELLOW=$'\033[38;2;249;226;175m'
readonly C_BLUE=$'\033[38;2;137;180;250m'
readonly C_RED=$'\033[38;2;243;139;168m'
readonly C_MAUVE=$'\033[38;2;203;164;247m'

_log() {
    printf "[%s] [HOTPLUG] [%s] %s\n" \
        "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" "$2" \
        | tee -a "$LOG_FILE" >/dev/null
}

log_info()  { _log "INFO" "$*"; echo -e "${C_BLUE}[HOTPLUG]${C_RESET} $*"; }
log_ok()    { _log "OK  " "$*"; echo -e "${C_GREEN}[HOTPLUG]${C_RESET} $*"; }
log_warn()  { _log "WARN" "$*"; echo -e "${C_YELLOW}[HOTPLUG]${C_RESET} $*" >&2; }
log_err()   { _log "ERR " "$*"; echo -e "${C_RED}[HOTPLUG]${C_RESET} $*" >&2; }

# ══════════════════════════════════════════════════════════════════════════════
# §01  MONITOR DETECTION
# ══════════════════════════════════════════════════════════════════════════════

_get_monitors() {
    hyprctl -j monitors 2>/dev/null | jq -r '.[].name' 2>/dev/null || true
}

_get_monitor_count() {
    hyprctl -j monitors 2>/dev/null | jq 'length' 2>/dev/null || echo 0
}

_monitor_info() {
    local name="$1"
    hyprctl -j monitors 2>/dev/null | \
        jq -r ".[] | select(.name == \"$name\") | \
        \"\(.name): \(.width)×\(.height)@\(.refreshRate|round)Hz scale:\(.scale)\"" \
        2>/dev/null || echo "unknown"
}

# ══════════════════════════════════════════════════════════════════════════════
# §02  LAYOUT PROFILES
# ══════════════════════════════════════════════════════════════════════════════

_apply_kanshi_profile() {
    if command -v kanshictl &>/dev/null; then
        kanshictl reload 2>/dev/null && \
            log_ok "Kanshi profile reloaded" || \
            log_warn "Kanshi reload failed"
    fi
}

_apply_single_monitor() {
    local mon="$1"
    log_info "Single monitor mode: $mon"
    hyprctl keyword monitor "$mon,preferred,0x0,auto" 2>/dev/null || true

    # Reassign all workspaces to single monitor
    for ws in $(seq 1 10); do
        hyprctl dispatch moveworkspacetomonitor "$ws $mon" 2>/dev/null || true
    done

    log_ok "All workspaces assigned to $mon"
}

_apply_dual_monitor() {
    local -a monitors=("$@")
    log_info "Dual monitor mode: ${monitors[*]}"

    local primary="${monitors[0]}"
    local secondary="${monitors[1]}"

    # Workspaces 1-5 → primary, 6-10 → secondary
    for ws in $(seq 1 5); do
        hyprctl dispatch moveworkspacetomonitor "$ws $primary" 2>/dev/null || true
    done
    for ws in $(seq 6 10); do
        hyprctl dispatch moveworkspacetomonitor "$ws $secondary" 2>/dev/null || true
    done

    log_ok "Workspaces 1-5→$primary, 6-10→$secondary"
}

_apply_triple_monitor() {
    local -a monitors=("$@")
    log_info "Triple monitor mode: ${monitors[*]}"

    # WS 1-3 → left, 4-7 → center, 8-10 → right
    for ws in 1 2 3; do
        hyprctl dispatch moveworkspacetomonitor "$ws ${monitors[0]}" 2>/dev/null || true
    done
    for ws in 4 5 6 7; do
        hyprctl dispatch moveworkspacetomonitor "$ws ${monitors[1]}" 2>/dev/null || true
    done
    for ws in 8 9 10; do
        hyprctl dispatch moveworkspacetomonitor "$ws ${monitors[2]}" 2>/dev/null || true
    done

    log_ok "Triple monitor workspaces assigned"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  WALLPAPER APPLICATION
# ══════════════════════════════════════════════════════════════════════════════

_apply_wallpaper() {
    local current_wallpaper
    current_wallpaper=$(cat "${HOME}/.cache/ash-dotfiles/current-wallpaper.jpg" \
        2>/dev/null || echo "${HOME}/.config/ash-dotfiles/assets/wallpapers/default-dark.jpg")

    if [[ -f "$current_wallpaper" ]] && command -v swww &>/dev/null; then
        swww img "$current_wallpaper" \
            --transition-type fade \
            --transition-duration 0.8 \
            --transition-fps 60 \
            2>/dev/null && \
            log_ok "Wallpaper applied to all monitors" || \
            log_warn "swww wallpaper apply failed"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  EVENT HANDLERS
# ══════════════════════════════════════════════════════════════════════════════

_on_monitor_added() {
    local monitor_name="$1"
    log_info "Monitor CONNECTED: $monitor_name"

    # Wait for monitor to be fully initialized
    sleep 0.5

    local count
    count="$(_get_monitor_count)"

    # Apply kanshi profile first (if available)
    _apply_kanshi_profile

    # Fall back to built-in logic
    mapfile -t monitors < <(_get_monitors)

    case "$count" in
        1) _apply_single_monitor "${monitors[0]}" ;;
        2) _apply_dual_monitor   "${monitors[@]}" ;;
        3) _apply_triple_monitor "${monitors[@]}" ;;
        *) log_info "More than 3 monitors — using kanshi only" ;;
    esac

    # Apply wallpaper
    sleep 0.3
    _apply_wallpaper

    # Reload Waybar
    pkill -SIGUSR1 waybar 2>/dev/null || true

    # Notify user
    local info
    info="$(_monitor_info "$monitor_name")"
    notify-send \
        "🖥 Monitor Connected" \
        "$info\nTotal displays: $count\nLayout applied automatically" \
        --urgency=normal \
        --expire-time=4000 \
        --hint=string:x-dunst-stack-tag:monitor-hotplug \
        2>/dev/null || true

    log_ok "Monitor connect handled: $monitor_name ($count total)"
    _log "INFO" "Monitor added: $monitor_name | count=$count"
}

_on_monitor_removed() {
    local monitor_name="$1"
    log_info "Monitor DISCONNECTED: $monitor_name"

    # Wait for Hyprland to process disconnection
    sleep 0.5

    local count
    count="$(_get_monitor_count)"

    _apply_kanshi_profile

    mapfile -t monitors < <(_get_monitors)

    case "$count" in
        0) log_warn "No monitors remaining — cannot apply layout" ;;
        1) _apply_single_monitor "${monitors[0]}" ;;
        2) _apply_dual_monitor   "${monitors[@]}" ;;
        3) _apply_triple_monitor "${monitors[@]}" ;;
    esac

    sleep 0.3
    _apply_wallpaper

    pkill -SIGUSR1 waybar 2>/dev/null || true

    notify-send \
        "🖥 Monitor Disconnected" \
        "$monitor_name removed\nRemaining: $count display(s)\nLayout adjusted" \
        --urgency=normal \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:monitor-hotplug \
        2>/dev/null || true

    log_ok "Monitor disconnect handled: $monitor_name ($count remaining)"
    _log "INFO" "Monitor removed: $monitor_name | count=$count"
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  IPC DAEMON (persistent listener)
# ══════════════════════════════════════════════════════════════════════════════

_daemon_listen() {
    log_info "Starting monitor hotplug daemon..."
    log_info "Listening on: $SOCKET"

    if [[ ! -S "$SOCKET" ]]; then
        log_err "Hyprland IPC socket not found: $SOCKET"
        log_err "Ensure HYPRLAND_INSTANCE_SIGNATURE is set"
        exit 1
    fi

    # Process initial state
    _handle_current_state

    # Listen for IPC events
    socat - "UNIX-CONNECT:${SOCKET}" 2>/dev/null | while read -r line; do
        case "$line" in
            "monitoradded>>"*)
                local mon="${line#monitoradded>>}"
                _on_monitor_added "$mon"
                ;;
            "monitorremoved>>"*)
                local mon="${line#monitorremoved>>}"
                _on_monitor_removed "$mon"
                ;;
        esac
    done
}

_handle_current_state() {
    local count
    count="$(_get_monitor_count)"
    mapfile -t monitors < <(_get_monitors)

    log_info "Initial state: $count monitor(s) connected"

    case "$count" in
        1) _apply_single_monitor "${monitors[0]}" ;;
        2) _apply_dual_monitor   "${monitors[@]}" ;;
        3) _apply_triple_monitor "${monitors[@]}" ;;
    esac
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  LIST MONITORS
# ══════════════════════════════════════════════════════════════════════════════

_list_monitors() {
    echo -e "\n${C_MAUVE}Connected Monitors:${C_RESET}"
    hyprctl -j monitors 2>/dev/null | \
        jq -r '.[] | "  \(.name): \(.width)×\(.height)@\(.refreshRate|round)Hz scale:\(.scale) pos:\(.x),\(.y)"' \
        2>/dev/null || echo "  No monitors or hyprctl unavailable"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    local cmd="${1:---daemon}"

    case "$cmd" in
        --daemon|-d)
            _daemon_listen
            ;;
        --once|-o)
            _handle_current_state
            ;;
        --list|-l)
            _list_monitors
            ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME [--daemon|--once|--list]"
            ;;
        *)
            log_err "Unknown option: $cmd"
            exit 1
            ;;
    esac
}

main "$@"