#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Idle Handler Script                              ║
# ║                                                                              ║
# ║  Manages idle timeout actions: dim screen, lock, DPMS off, suspend.       ║
# ║  Works alongside hypridle as a scripted extension for custom actions        ║
# ║  like saving session, syncing cloud, closing sensitive apps.               ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    idle-handler.sh dim          — dim screen action                         ║
# ║    idle-handler.sh undim        — restore brightness                        ║
# ║    idle-handler.sh lock         — lock screen                               ║
# ║    idle-handler.sh suspend      — suspend system                            ║
# ║    idle-handler.sh dpms-off     — turn displays off                         ║
# ║    idle-handler.sh dpms-on      — turn displays on                          ║
# ║    idle-handler.sh status       — show idle state                           ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/idle.log"
readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-idle"
readonly DIM_STATE="${STATE_DIR}/dim-brightness"

readonly C_RESET=$'\033[0m'
readonly C_BLUE=$'\033[38;2;137;180;250m'
readonly C_GREEN=$'\033[38;2;166;227;161m'
readonly C_YELLOW=$'\033[38;2;249;226;175m'

_log() {
    printf "[%s] [IDLE] [%s] %s\n" \
        "$(date '+%Y-%m-%dT%H:%M:%S')" "$1" "$2" \
        | tee -a "$LOG_FILE" >/dev/null
}

log_info() { _log "INFO" "$*"; }
log_ok()   { _log "OK  " "$*"; }
log_warn() { _log "WARN" "$*"; }

_setup() {
    mkdir -p "$STATE_DIR" "$(dirname "$LOG_FILE")"
}

# ══════════════════════════════════════════════════════════════════════════════
# §01  DIM / UNDIM
# ══════════════════════════════════════════════════════════════════════════════

_dim_screen() {
    log_info "Dimming screen..."

    if command -v brightnessctl &>/dev/null; then
        # Save current brightness
        local current
        current=$(brightnessctl get 2>/dev/null || echo 100)
        echo "$current" > "$DIM_STATE"

        # Dim to 20%
        brightnessctl set 20% 2>/dev/null && \
            log_ok "Screen dimmed to 20% (was: $current)"
    fi

    # Reduce gamma via hyprsunset if available
    if command -v hyprsunset &>/dev/null && ! pgrep -x hyprsunset > /dev/null; then
        hyprsunset -t 2700 2>/dev/null || true
    fi
}

_undim_screen() {
    log_info "Restoring screen brightness..."

    if command -v brightnessctl &>/dev/null; then
        if [[ -f "$DIM_STATE" ]]; then
            local saved
            saved=$(cat "$DIM_STATE")
            brightnessctl set "$saved" 2>/dev/null && \
                log_ok "Brightness restored to $saved"
            rm -f "$DIM_STATE"
        else
            brightnessctl set 80% 2>/dev/null && \
                log_ok "Brightness restored to 80% (default)"
        fi
    fi

    # Restore color temperature
    if pgrep -x hyprsunset > /dev/null 2>&1; then
        pkill hyprsunset 2>/dev/null || true
    fi
    hyprsunset -t 6500 2>/dev/null &
}

# ══════════════════════════════════════════════════════════════════════════════
# §02  LOCK SCREEN
# ══════════════════════════════════════════════════════════════════════════════

_lock_screen() {
    log_info "Initiating lock screen..."

    # Skip if already locked
    if pgrep -x hyprlock > /dev/null 2>&1; then
        log_warn "hyprlock already running"
        return 0
    fi

    # Pre-lock actions
    # Save clipboard (cliphist persistence)
    cliphist list > "${STATE_DIR}/clipboard-backup.txt" 2>/dev/null || true

    # Mute microphone on lock
    wpctl set-mute @DEFAULT_SOURCE@ 1 2>/dev/null || true

    # Enable DND while locked
    swaync-client --dnd-on 2>/dev/null || true

    # Lock
    hyprlock --immediate 2>/dev/null &

    log_ok "Lock screen activated"
    _log "INFO" "Screen locked at $(date -Iseconds)"
}

# ══════════════════════════════════════════════════════════════════════════════
# §03  DPMS CONTROL
# ══════════════════════════════════════════════════════════════════════════════

_dpms_off() {
    log_info "Turning displays off (DPMS)..."
    hyprctl dispatch dpms off 2>/dev/null && \
        log_ok "Displays: OFF" || \
        log_warn "DPMS off failed"
    _log "INFO" "DPMS off at $(date -Iseconds)"
}

_dpms_on() {
    log_info "Turning displays on (DPMS)..."
    hyprctl dispatch dpms on 2>/dev/null && \
        log_ok "Displays: ON" || \
        log_warn "DPMS on failed"

    # Restore wallpaper after DPMS on
    local wallpaper
    wallpaper=$(cat "${HOME}/.cache/ash-dotfiles/current-wallpaper.jpg" \
        2>/dev/null || echo "")
    [[ -f "$wallpaper" ]] && \
        swww img "$wallpaper" --transition-type none 2>/dev/null || true

    _log "INFO" "DPMS on at $(date -Iseconds)"
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  SUSPEND
# ══════════════════════════════════════════════════════════════════════════════

_suspend() {
    log_info "Initiating system suspend..."

    # Pre-suspend: save ASH session
    ash session save 2>/dev/null || true

    # Sync filesystems
    sync

    log_ok "Suspending..."
    _log "INFO" "Suspend initiated at $(date -Iseconds)"

    systemctl suspend
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  POST-RESUME HOOK
# ══════════════════════════════════════════════════════════════════════════════

_on_resume() {
    log_info "System resumed from suspend..."

    # Restore DND state
    swaync-client --dnd-off 2>/dev/null || true

    # Restore microphone
    wpctl set-mute @DEFAULT_SOURCE@ 0 2>/dev/null || true

    # Refresh network
    nmcli networking off 2>/dev/null || true
    sleep 0.3
    nmcli networking on 2>/dev/null || true

    # Re-sync displays
    hyprctl dispatch dpms on 2>/dev/null || true

    # Refresh Bluetooth
    systemctl restart bluetooth 2>/dev/null || true

    _log "INFO" "Resume handled at $(date -Iseconds)"
    log_ok "System resumed — services restored"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  STATUS
# ══════════════════════════════════════════════════════════════════════════════

_idle_status() {
    echo -e "${C_BLUE}Idle Handler Status${C_RESET}"
    echo "  hypridle:  $(pgrep -x hypridle > /dev/null && echo running || echo stopped)"
    echo "  hyprlock:  $(pgrep -x hyprlock > /dev/null && echo running || echo stopped)"
    echo "  dimmed:    $([[ -f "$DIM_STATE" ]] && echo yes || echo no)"
    echo "  DND:       $(swaync-client --dnd-state 2>/dev/null | grep -q true && echo on || echo off)"
    echo "  Displays:  $(hyprctl -j monitors 2>/dev/null | jq -r '.[0].dpmsStatus | if . then "on" else "off" end' 2>/dev/null || echo unknown)"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  MAIN
# ══════════════════════════════════════════════════════════════════════════════

main() {
    _setup

    case "${1:-status}" in
        dim)        _dim_screen   ;;
        undim)      _undim_screen ;;
        lock)       _lock_screen  ;;
        suspend)    _suspend      ;;
        dpms-off)   _dpms_off     ;;
        dpms-on)    _dpms_on      ;;
        resume)     _on_resume    ;;
        status)     _idle_status  ;;
        --help|-h)
            echo "Usage: $(basename "$0") [dim|undim|lock|suspend|dpms-off|dpms-on|resume|status]"
            ;;
        *)
            echo "Unknown command: $1" >&2
            exit 1
            ;;
    esac
}

main "$@"