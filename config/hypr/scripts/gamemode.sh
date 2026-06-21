#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES v5.0 OMEGA — Game Mode Toggle Script                          ║
# ║                                                                              ║
# ║  Toggles full game mode: strips compositor overhead, sets CPU/GPU to       ║
# ║  performance, enables VRR, disables notifications, manages MangoHUD,       ║
# ║  handles game process lifecycle and auto-restores on exit.                  ║
# ║                                                                              ║
# ║  Usage:                                                                      ║
# ║    gamemode.sh on              — activate game mode                         ║
# ║    gamemode.sh off             — deactivate game mode                       ║
# ║    gamemode.sh toggle          — toggle current state                       ║
# ║    gamemode.sh status          — show current state                         ║
# ║    gamemode.sh auto GAMEBIN    — auto-manage for a game process             ║
# ║    gamemode.sh optimize PID    — optimize settings for running game PID     ║
# ╚══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

# ══════════════════════════════════════════════════════════════════════════════
# §01  CONSTANTS & CONFIGURATION
# ══════════════════════════════════════════════════════════════════════════════

readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"
readonly SCRIPT_VERSION="5.0.0"

# ── State files ───────────────────────────────────────────────────────────────
readonly STATE_DIR="${XDG_RUNTIME_DIR:-/tmp}/ash-gamemode"
readonly STATE_FILE="${STATE_DIR}/state"
readonly PID_FILE="${STATE_DIR}/inhibit.pid"
readonly LOG_FILE="${HOME}/.local/state/ash-dotfiles/logs/gamemode.log"
readonly BACKUP_FILE="${STATE_DIR}/compositor-backup.json"

# ── ASH integration ───────────────────────────────────────────────────────────
readonly ASH_MODE_FILE="${HOME}/.local/state/ash-dotfiles/current-mode"
readonly ASH_ICON="${HOME}/.config/ash-dotfiles/assets/icons/ash-system/game-mode.svg"

# ── Waybar signal ─────────────────────────────────────────────────────────────
readonly WAYBAR_SIGNAL=SIGUSR1

# ── Colors for output ─────────────────────────────────────────────────────────
readonly C_RESET='\033[0m'
readonly C_BOLD='\033[1m'
readonly C_GREEN='\033[38;2;166;227;161m'
readonly C_RED='\033[38;2;243;139;168m'
readonly C_YELLOW='\033[38;2;249;226;175m'
readonly C_BLUE='\033[38;2;137;180;250m'
readonly C_MAUVE='\033[38;2;203;164;247m'
readonly C_GREY='\033[38;2;127;132;156m'

# ══════════════════════════════════════════════════════════════════════════════
# §02  LOGGING
# ══════════════════════════════════════════════════════════════════════════════

_log() {
    local level="$1"; shift
    local msg="$*"
    local timestamp
    timestamp="$(date '+%Y-%m-%dT%H:%M:%S')"
    printf "[%s] [GAMEMODE] [%s] %s\n" "$timestamp" "$level" "$msg" \
        | tee -a "$LOG_FILE" >/dev/null
}

log_info()  { _log "INFO " "$*"; echo -e "${C_BLUE}[INFO]${C_RESET}  $*"; }
log_ok()    { _log "OK   " "$*"; echo -e "${C_GREEN}[ OK ]${C_RESET}  $*"; }
log_warn()  { _log "WARN " "$*"; echo -e "${C_YELLOW}[WARN]${C_RESET}  $*"; }
log_err()   { _log "ERROR" "$*"; echo -e "${C_RED}[ERR ]${C_RESET}  $*" >&2; }
log_step()  { echo -e "\n${C_BOLD}${C_MAUVE}──── $* ────${C_RESET}"; }

# ══════════════════════════════════════════════════════════════════════════════
# §03  PREREQUISITE CHECKS
# ══════════════════════════════════════════════════════════════════════════════

_check_deps() {
    local -a required=(hyprctl notify-send)
    local -a missing=()
    for dep in "${required[@]}"; do
        command -v "$dep" &>/dev/null || missing+=("$dep")
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        log_err "Missing dependencies: ${missing[*]}"
        exit 1
    fi
}

_setup_dirs() {
    mkdir -p "$STATE_DIR"
    mkdir -p "$(dirname "$LOG_FILE")"
}

_hyprctl() {
    hyprctl "$@" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §04  STATE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

_get_state() {
    if [[ -f "$STATE_FILE" ]]; then
        cat "$STATE_FILE"
    else
        echo "off"
    fi
}

_set_state() {
    echo "$1" > "$STATE_FILE"
    echo "$1" > "$ASH_MODE_FILE" 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §05  COMPOSITOR BACKUP & RESTORE
# ══════════════════════════════════════════════════════════════════════════════

_backup_compositor() {
    log_info "Backing up compositor state..."
    local backup
    backup=$(cat << EOF
{
    "blur":          $(hyprctl -j getoption decoration:blur:enabled   | jq '.int'),
    "shadow":        $(hyprctl -j getoption decoration:shadow:enabled  | jq '.int'),
    "rounding":      $(hyprctl -j getoption decoration:rounding        | jq '.int'),
    "gaps_in":       $(hyprctl -j getoption general:gaps_in            | jq '.int'),
    "gaps_out":      $(hyprctl -j getoption general:gaps_out           | jq '.int'),
    "border_size":   $(hyprctl -j getoption general:border_size        | jq '.int'),
    "vfr":           $(hyprctl -j getoption misc:vfr                   | jq '.int'),
    "vrr":           $(hyprctl -j getoption misc:vrr                   | jq '.int'),
    "anim_enabled":  $(hyprctl -j getoption animations:enabled         | jq '.int'),
    "dim_inactive":  $(hyprctl -j getoption decoration:dim_inactive    | jq '.int'),
    "inactive_opacity": $(hyprctl -j getoption decoration:inactive_opacity | jq '.float'),
    "allow_tearing": $(hyprctl -j getoption general:allow_tearing      | jq '.int')
}
EOF
    )
    echo "$backup" > "$BACKUP_FILE"
    log_ok "Compositor state backed up to $BACKUP_FILE"
}

_restore_compositor() {
    if [[ ! -f "$BACKUP_FILE" ]]; then
        log_warn "No backup found — reloading config instead"
        _hyprctl reload
        return
    fi

    log_info "Restoring compositor state..."
    local backup
    backup=$(cat "$BACKUP_FILE")

    _hyprctl keyword decoration:blur:enabled    "$(jq -r '.blur'          <<< "$backup")"
    _hyprctl keyword decoration:shadow:enabled  "$(jq -r '.shadow'        <<< "$backup")"
    _hyprctl keyword decoration:rounding        "$(jq -r '.rounding'      <<< "$backup")"
    _hyprctl keyword general:gaps_in            "$(jq -r '.gaps_in'       <<< "$backup")"
    _hyprctl keyword general:gaps_out           "$(jq -r '.gaps_out'      <<< "$backup")"
    _hyprctl keyword general:border_size        "$(jq -r '.border_size'   <<< "$backup")"
    _hyprctl keyword misc:vfr                   "$(jq -r '.vfr'           <<< "$backup")"
    _hyprctl keyword misc:vrr                   "$(jq -r '.vrr'           <<< "$backup")"
    _hyprctl keyword animations:enabled         "$(jq -r '.anim_enabled'  <<< "$backup")"
    _hyprctl keyword decoration:dim_inactive    "$(jq -r '.dim_inactive'  <<< "$backup")"
    _hyprctl keyword decoration:inactive_opacity "$(jq -r '.inactive_opacity' <<< "$backup")"
    _hyprctl keyword general:allow_tearing      "$(jq -r '.allow_tearing' <<< "$backup")"

    rm -f "$BACKUP_FILE"
    log_ok "Compositor state restored"
}

# ══════════════════════════════════════════════════════════════════════════════
# §06  COMPOSITOR OPTIMIZATION
# ══════════════════════════════════════════════════════════════════════════════

_strip_compositor() {
    log_step "Stripping compositor overhead"

    # ── Kill blur (biggest GPU saver) ─────────────────────────────────────────
    _hyprctl keyword decoration:blur:enabled         false
    log_ok "Blur: OFF"

    # ── Kill shadow ───────────────────────────────────────────────────────────
    _hyprctl keyword decoration:shadow:enabled       false
    log_ok "Shadow: OFF"

    # ── Kill rounding ─────────────────────────────────────────────────────────
    _hyprctl keyword decoration:rounding             0
    log_ok "Rounding: OFF"

    # ── Kill dim ──────────────────────────────────────────────────────────────
    _hyprctl keyword decoration:dim_inactive         false
    log_ok "Dim: OFF"

    # ── Full opacity everywhere ───────────────────────────────────────────────
    _hyprctl keyword decoration:inactive_opacity     1.0
    _hyprctl keyword decoration:active_opacity       1.0
    log_ok "Opacity: 100%"

    # ── Zero gaps ─────────────────────────────────────────────────────────────
    _hyprctl keyword general:gaps_in                 0
    _hyprctl keyword general:gaps_out                0
    log_ok "Gaps: ZERO"

    # ── Zero borders ─────────────────────────────────────────────────────────
    _hyprctl keyword general:border_size             0
    log_ok "Borders: OFF"

    # ── Kill animations ───────────────────────────────────────────────────────
    _hyprctl keyword animations:enabled              false
    log_ok "Animations: OFF"

    # ── Allow tearing (for games that benefit) ───────────────────────────────
    _hyprctl keyword general:allow_tearing           true
    log_ok "Tearing: ALLOWED"

    # ── VFR off (stable frame delivery) ──────────────────────────────────────
    _hyprctl keyword misc:vfr                        false
    log_ok "VFR: OFF (stable)"

    # ── VRR: fullscreen only ─────────────────────────────────────────────────
    _hyprctl keyword misc:vrr                        1
    log_ok "VRR: Fullscreen (G-Sync/FreeSync)"

    # ── Unfocused FPS cap very low ────────────────────────────────────────────
    _hyprctl keyword misc:render_unfocused_fps       5
    log_ok "Background FPS: 5"
}

# ══════════════════════════════════════════════════════════════════════════════
# §07  CPU/GPU PERFORMANCE
# ══════════════════════════════════════════════════════════════════════════════

_set_performance() {
    log_step "Setting CPU/GPU to performance"

    # ── power-profiles-daemon ─────────────────────────────────────────────────
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set performance 2>/dev/null && \
            log_ok "Power profile: performance" || \
            log_warn "powerprofilesctl failed"
    fi

    # ── CPU governor ──────────────────────────────────────────────────────────
    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        echo performance | \
            sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor \
            > /dev/null 2>/dev/null && \
            log_ok "CPU governor: performance" || \
            log_warn "CPU governor change failed (sudo required)"
    fi

    # ── AMD GPU performance ───────────────────────────────────────────────────
    for card in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
        [[ -f "$card" ]] && \
            echo high | sudo tee "$card" > /dev/null 2>/dev/null && \
            log_ok "AMD GPU: high performance" && break
    done

    # ── GameMode daemon ───────────────────────────────────────────────────────
    if command -v gamemoded &>/dev/null; then
        systemctl --user start gamemode 2>/dev/null && \
            log_ok "GameMode daemon: started" || true
    fi
}

_restore_performance() {
    log_step "Restoring balanced performance"

    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set balanced 2>/dev/null && \
            log_ok "Power profile: balanced" || true
    fi

    if [[ -d /sys/devices/system/cpu/cpu0/cpufreq ]]; then
        echo schedutil | \
            sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor \
            > /dev/null 2>/dev/null && \
            log_ok "CPU governor: schedutil" || true
    fi

    for card in /sys/class/drm/card*/device/power_dpm_force_performance_level; do
        [[ -f "$card" ]] && \
            echo auto | sudo tee "$card" > /dev/null 2>/dev/null && \
            log_ok "AMD GPU: auto" && break
    done
}

# ══════════════════════════════════════════════════════════════════════════════
# §08  NOTIFICATION MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

_silence_notifications() {
    command -v swaync-client &>/dev/null && \
        swaync-client --dnd-on 2>/dev/null && \
        log_ok "DND: ON (no notifications)"
}

_restore_notifications() {
    command -v swaync-client &>/dev/null && \
        swaync-client --dnd-off 2>/dev/null && \
        log_ok "DND: OFF (notifications restored)"
}

# ══════════════════════════════════════════════════════════════════════════════
# §09  IDLE INHIBIT
# ══════════════════════════════════════════════════════════════════════════════

_inhibit_idle() {
    if command -v systemd-inhibit &>/dev/null; then
        systemd-inhibit \
            --what=idle:sleep:handle-lid-switch \
            --who="ASH Game Mode" \
            --why="Game in progress" \
            sleep infinity &
        echo $! > "$PID_FILE"
        log_ok "Idle inhibit: ACTIVE (PID: $!)"
    fi
}

_release_inhibit() {
    if [[ -f "$PID_FILE" ]]; then
        local pid
        pid=$(cat "$PID_FILE")
        kill "$pid" 2>/dev/null && \
            log_ok "Idle inhibit: RELEASED" || true
        rm -f "$PID_FILE"
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# §10  WAYBAR UPDATE
# ══════════════════════════════════════════════════════════════════════════════

_update_waybar() {
    pkill -"$WAYBAR_SIGNAL" waybar 2>/dev/null || true
}

# ══════════════════════════════════════════════════════════════════════════════
# §11  WORKSPACE MANAGEMENT
# ══════════════════════════════════════════════════════════════════════════════

_prepare_game_workspace() {
    # Switch to workspace 6 (gaming workspace)
    _hyprctl dispatch workspace 6
    log_ok "Switched to gaming workspace 6"
}

# ══════════════════════════════════════════════════════════════════════════════
# §12  GAME MODE ON
# ══════════════════════════════════════════════════════════════════════════════

_gamemode_on() {
    log_step "Activating Game Mode"

    if [[ "$(_get_state)" == "game" ]]; then
        log_warn "Game mode already active"
        return 0
    fi

    _backup_compositor
    _strip_compositor
    _set_performance
    _silence_notifications
    _inhibit_idle
    _prepare_game_workspace
    _set_state "game"
    _update_waybar

    notify-send \
        "🎮 Game Mode ACTIVATED" \
        "Blur ✖ | Shadow ✖ | Anim ✖ | Gaps ✖\nVRR ✔ | Tearing ✔ | CPU: max\nGPU: max performance" \
        --app-name="ASH Game Mode" \
        --icon="$ASH_ICON" \
        --urgency=normal \
        --expire-time=4000 \
        --hint=string:x-dunst-stack-tag:ash-gamemode \
        2>/dev/null || true

    log_ok "Game Mode: ACTIVE ✓"
    _log "INFO" "Game mode activated at $(date -Iseconds)"
}

# ══════════════════════════════════════════════════════════════════════════════
# §13  GAME MODE OFF
# ══════════════════════════════════════════════════════════════════════════════

_gamemode_off() {
    log_step "Deactivating Game Mode"

    if [[ "$(_get_state)" != "game" ]]; then
        log_warn "Game mode not active"
        return 0
    fi

    _restore_compositor
    _restore_performance
    _restore_notifications
    _release_inhibit
    _set_state "default"
    _update_waybar

    notify-send \
        "✅ Game Mode DEACTIVATED" \
        "Compositor restored to default settings\nBlur ✔ | Shadow ✔ | Balanced power" \
        --app-name="ASH Game Mode" \
        --urgency=low \
        --expire-time=3000 \
        --hint=string:x-dunst-stack-tag:ash-gamemode \
        2>/dev/null || true

    log_ok "Game Mode: INACTIVE ✓"
    _log "INFO" "Game mode deactivated at $(date -Iseconds)"
}

# ══════════════════════════════════════════════════════════════════════════════
# §14  AUTO MODE (Process-aware game management)
# ══════════════════════════════════════════════════════════════════════════════

_gamemode_auto() {
    local game_bin="${1:-}"

    if [[ -z "$game_bin" ]]; then
        log_err "Usage: $SCRIPT_NAME auto GAME_BINARY"
        exit 1
    fi

    log_info "Auto mode: watching for process '$game_bin'"
    _gamemode_on

    # Wait for game to start
    local wait_count=0
    while ! pgrep -x "$game_bin" > /dev/null 2>&1; do
        sleep 1
        ((wait_count++))
        if [[ $wait_count -gt 30 ]]; then
            log_warn "Game process not found after 30s — staying in game mode"
            break
        fi
    done

    if pgrep -x "$game_bin" > /dev/null 2>&1; then
        log_ok "Game process detected: $game_bin"
        # Monitor game process — restore when it exits
        while pgrep -x "$game_bin" > /dev/null 2>&1; do
            sleep 2
        done
        log_info "Game process ended: $game_bin"
    fi

    _gamemode_off
}

# ══════════════════════════════════════════════════════════════════════════════
# §15  STATUS DISPLAY
# ══════════════════════════════════════════════════════════════════════════════

_gamemode_status() {
    local state
    state="$(_get_state)"

    echo -e "\n${C_BOLD}${C_MAUVE}ASH Game Mode Status${C_RESET}"
    echo -e "${C_GREY}════════════════════${C_RESET}"

    if [[ "$state" == "game" ]]; then
        echo -e "  State:    ${C_GREEN}${C_BOLD}ACTIVE${C_RESET} 🎮"
    else
        echo -e "  State:    ${C_GREY}inactive${C_RESET}"
    fi

    echo -e "  Blur:     $(hyprctl -j getoption decoration:blur:enabled 2>/dev/null | jq -r 'if .int == 1 then "on" else "off" end' 2>/dev/null || echo 'N/A')"
    echo -e "  Shadow:   $(hyprctl -j getoption decoration:shadow:enabled 2>/dev/null | jq -r 'if .int == 1 then "on" else "off" end' 2>/dev/null || echo 'N/A')"
    echo -e "  VRR:      $(hyprctl -j getoption misc:vrr 2>/dev/null | jq -r '.int' 2>/dev/null || echo 'N/A')"
    echo -e "  Power:    $(powerprofilesctl get 2>/dev/null || echo 'N/A')"
    echo -e "  Inhibit:  $([[ -f "$PID_FILE" ]] && echo 'active' || echo 'none')"
    echo ""
}

# ══════════════════════════════════════════════════════════════════════════════
# §16  MAIN DISPATCH
# ══════════════════════════════════════════════════════════════════════════════

main() {
    _check_deps
    _setup_dirs

    local cmd="${1:-toggle}"

    case "$cmd" in
        on|enable|activate)
            _gamemode_on
            ;;
        off|disable|deactivate)
            _gamemode_off
            ;;
        toggle)
            if [[ "$(_get_state)" == "game" ]]; then
                _gamemode_off
            else
                _gamemode_on
            fi
            ;;
        auto)
            _gamemode_auto "${2:-}"
            ;;
        status)
            _gamemode_status
            ;;
        --help|-h)
            echo "Usage: $SCRIPT_NAME [on|off|toggle|status|auto BINARY]"
            exit 0
            ;;
        *)
            log_err "Unknown command: $cmd"
            echo "Usage: $SCRIPT_NAME [on|off|toggle|status|auto BINARY]"
            exit 1
            ;;
    esac
}

main "$@"