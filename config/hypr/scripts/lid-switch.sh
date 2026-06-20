#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Lid Switch Handler                               ║
# ║                                                                              ║
# ║  Handles laptop lid open/close events with smart dock detection,           ║
# ║  display management, lock screen, suspend policies and external            ║
# ║  monitor awareness.                                                          ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    lid-switch.sh closed     — lid was closed                               ║
# ║    lid-switch.sh opened     — lid was opened                               ║
# ║    lid-switch.sh status     — current lid state                            ║
# ║    lid-switch.sh --daemon   — run as systemd service listener               ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/lid-switch.log"
readonly LID_STATE_FILE="/proc/acpi/button/lid/LID/state"
readonly LID_STATE_FILE_ALT="/proc/acpi/button/lid/LID0/state"

readonly C_RESET='\033[0m'
readonly C_GREEN='\033[38;2;166;227;161m'
readonly C_YELLOW='\033[38;2;249;226;175m'
readonly C_BLUE='\033[38;2;137;180;250m'
readonly C_RED='\033[38;2;243;139;168m'

_log() {
    printf "[%s] [LID] [%s] %s\n" \
        "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" "$2" \
        | tee -a "$LOG_FILE" >/dev/null
}

log_info() { _log "INFO" "$*"; echo -e "${C_BLUE}[LID]${C_RESET} $*"; }
log_ok()   { _log "OK  " "$*"; echo -e "${C_GREEN}[LID]${C_RESET} $*"; }
log_warn() { _log "WARN" "$*"; echo -e "${C_YELLOW}[LID]${C_RESET} $*"; }

# ══════════════════════════════════════════════════════════════════════════════
# §01  DETECTION
# ══════════════════════════════════════════════════════════════════════════════

_has_external_monitor() {
    local count
    count=$(hyprctl -j monitors 2>/dev/null | jq 'length' 2>/dev/null || echo 1)
    [[ "$count" -gt 1 ]]
}

_get_lid_state() {
    local state_file
    if [[ -f "$LID_STATE_FILE" ]]; then
        state_file="$LID_STATE_FILE"
    elif [[ -f "$LID_STATE_FILE_ALT" ]]; then
        state_file="$LID_STATE_FILE_ALT"
    else
        echo "unknown"
        return
    fi

    if grep -q "open" "$state_file" 2>/dev/null; then
        echo "open"
    else
        echo "closed"
    fi
}

_is_docked() {
    # Check if AC power and external monitor
    local ac
    ac=$(cat /sys/class/power_supply/AC*/online 2>/dev/null | head -1 || echo 0)
    _has_external_monitor && [[ "$ac" == "1" ]]
}

# ══════════════════════════════════════════════════════════════════════════════
# §02  LID CLOSED HANDLING
# ══════════════════════════════════════════════════════════════════════════════

_on_lid_closed() {
    log_info "Lid CLOSED detected"

    if _is_docked; then
        log_info "Docked mode: external monitor present + AC power"
        _handle_docked_close
    else
        log_info "Undocked mode: no external monitor"
        _handle_undocked_close
    fi
}

_handle_docked_close() {
    # Disable laptop screen, keep external
    local internal
    internal=$(hyprctl -j monitors 2>/dev/null | \
        jq -r '.[] | select(.name | test("eDP")) | .name' 2>/dev/null | head -1)

    if [[ -n "$internal" ]]; then
        hyprctl keyword monitor "$internal,disable" 2>/dev/null && \
            log_ok "Internal display ($internal) disabled — docked mode"

        # Reassign any workspaces from internal to first external
        local external
        external=$(hyprctl -j monitors 2>/dev/null | \
            jq -r '.[] | select(.name | test("eDP") | not) | .name' \
            2>/dev/null | head -1)

        if [[ -n "$external" ]]; then
            for ws in $(seq 1 10); do
                hyprctl dispatch moveworkspacetomonitor "$ws $external" 2>/dev/null || true
            done
            log_ok "All workspaces moved to $external"
        fi
    fi

    notify-send \
        "💻 Docked Mode" \
        "Internal display disabled\nExternal monitor active" \
        --urgency=low --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:lid-switch \
        2>/dev/null || true

    _log "INFO" "Lid closed (docked) at $(date -Iseconds)"
}

_handle_undocked_close() {
    # Lock and suspend
    log_info "Locking screen before suspend..."

    hyprlock --immediate 2>/dev/null &
    sleep 0.5

    # Check suspend policy from ASH config
    local policy
    policy=$(cat "${HOME}/.config/ash-dotfiles/ash-cli/data/ash.conf" 2>/dev/null | \
        grep "lid_close_action" | cut -d= -f2 | xargs 2>/dev/null || echo "suspend")

    case "$policy" in
        suspend)
            log_info "Suspending system..."
            systemctl suspend
            ;;
        hibernate)
            log_info "Hibernating system..."
            systemctl hibernate
            ;;
        lock)
            log_info "Lock only (no suspend)"
            ;;
        nothing)
            log_info "No action on lid close"
            ;;
    esac

    _log "INFO" "Lid closed (undocked) — action: $policy"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  LID OPENED HANDLING
# ══════════════════════════════════════════════════════════════════════════════

_on_lid_opened() {
    log_info "Lid OPENED detected"

    # Wait for display to initialize
    sleep 0.5

    # Re-enable internal display
    local internal
    internal=$(hyprctl -j monitors 2>/dev/null | \
        jq -r '.[] | select(.name | test("eDP")) | .name' 2>/dev/null | head -1)

    # If internal was disabled, re-enable it
    if ! hyprctl -j monitors 2>/dev/null | \
        jq -e '.[] | select(.name | test("eDP"))' > /dev/null 2>&1; then
        hyprctl keyword monitor "eDP-1,preferred,0x0,auto" 2>/dev/null && \
            log_ok "Internal display re-enabled" || \
            log_warn "Could not re-enable internal display"
    fi

    # Turn on DPMS
    hyprctl dispatch dpms on 2>/dev/null || true

    # Restore wallpaper
    local wallpaper
    wallpaper=$(cat "${HOME}/.cache/ash-dotfiles/current-wallpaper.jpg" \
        2>/dev/null || echo "")
    if [[ -f "$wallpaper" ]] && command -v swww &>/dev/null; then
        swww img "$wallpaper" --transition-type fade 2>/dev/null || true
    fi

    notify-send \
        "💻 Lid Opened" \
        "Display restored" \
        --urgency=low --expire-time=2000 \
        --hint=string:x-dunst-stack-tag:lid-switch \
        2>/dev/null || true

    _log "INFO" "Lid opened at $(date -Iseconds)"
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  DAEMON MODE
# ══════════════════════════════════════════════════════════════════════════════

_daemon_listen() {
    log_info "Lid switch daemon started"

    local prev_state
    prev_state="$(_get_lid_state)"
    log_info "Initial lid state: $prev_state"

    while true; do
        sleep 1
        local current_state
        current_state="$(_get_lid_state)"

        if [[ "$current_state" != "$prev_state" ]]; then
            case "$current_state" in
                closed) _on_lid_closed ;;
                open)   _on_lid_opened ;;
            esac
            prev_state="$current_state"
        fi
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    mkdir -p "$(dirname "$LOG_FILE")"

    local cmd="${1:-status}"

    case "$cmd" in
        closed)     _on_lid_closed ;;
        opened|open) _on_lid_opened ;;
        status)
            echo "Lid state: $(_get_lid_state)"
            echo "Docked:    $(_is_docked && echo yes || echo no)"
            ;;
        --daemon|-d) _daemon_listen ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME [closed|opened|status|--daemon]"
            ;;
        *)
            log_warn "Unknown command: $cmd"
            exit 1
            ;;
    esac
}

main "$@"