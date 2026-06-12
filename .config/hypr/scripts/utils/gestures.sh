#!/bin/bash
set -euo pipefail
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — GESTURE CONFIGURATION                        ║
# ║           Configure and toggle touchpad gestures                           ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/gestures.log"
readonly CONFIG_FILE="${HOME}/.config/libinput-gestures.conf"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🤌 GESTURE CONFIGURATION
# ═══════════════════════════════════════════════════════════════════════════════

create_gesture_config() {
    mkdir -p "$(dirname "${CONFIG_FILE}")"

    cat > "${CONFIG_FILE}" << 'EOF'
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║  ASH DOTFILES — libinput-gestures configuration                             ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝

# ── 3-Finger Swipe ────────────────────────────────────────────────────────────
# Left/Right: Switch workspaces
gesture swipe left  3 hyprctl dispatch workspace e+1
gesture swipe right 3 hyprctl dispatch workspace e-1

# Up: Show overview / launch Rofi
gesture swipe up    3 bash -c "~/.config/rofi/scripts/launcher.sh"

# Down: Show desktop (minimize all)
gesture swipe down  3 hyprctl dispatch togglespecialworkspace overview

# ── 4-Finger Swipe ────────────────────────────────────────────────────────────
# Left/Right: Move window to next/prev workspace
gesture swipe left  4 hyprctl dispatch movetoworkspace e+1
gesture swipe right 4 hyprctl dispatch movetoworkspace e-1

# Up: Overview
gesture swipe up    4 bash -c "~/.config/rofi/scripts/window-switcher.sh"

# Down: Close window
gesture swipe down  4 hyprctl dispatch killactive

# ── Pinch ─────────────────────────────────────────────────────────────────────
# Pinch in: Zoom out
gesture pinch in    2 bash -c "~/.config/hypr/scripts/hardware/magnifier.sh zoom-out"

# Pinch out: Zoom in
gesture pinch out   2 bash -c "~/.config/hypr/scripts/hardware/magnifier.sh zoom-in"

# ── Hold ──────────────────────────────────────────────────────────────────────
# 3-finger hold: Right-click equivalent (context menu)
# gesture hold on   3 xdotool click 3
EOF

    ok "Gesture config created: ${CONFIG_FILE}"
}

start_gestures() {
    if ! command -v libinput-gestures &>/dev/null; then
        warn "libinput-gestures not installed"
        warn "Install: paru -S libinput-gestures"
        return 1
    fi

    # Ensure user is in input group
    if ! groups | grep -q input; then
        warn "User not in 'input' group"
        warn "Fix: sudo usermod -aG input ${USER}"
        warn "Then log out and back in"
    fi

    # Create config if missing
    [[ ! -f "${CONFIG_FILE}" ]] && create_gesture_config

    # Stop existing instance
    libinput-gestures-setup stop 2>/dev/null || true
    sleep 0.3

    # Start daemon
    libinput-gestures-setup start
    ok "libinput-gestures started"
    log "INFO" "Gestures started"
}

stop_gestures() {
    if command -v libinput-gestures-setup &>/dev/null; then
        libinput-gestures-setup stop 2>/dev/null || true
        ok "libinput-gestures stopped"
        log "INFO" "Gestures stopped"
    fi
}

toggle_gestures() {
    if pgrep -x libinput-gestures &>/dev/null; then
        stop_gestures
        notify-send "🤌 Gestures" "Disabled" --app-name="ASH" \
            --expire-time=2000 2>/dev/null || true
    else
        start_gestures
        notify-send "🤌 Gestures" "Enabled" --app-name="ASH" \
            --expire-time=2000 2>/dev/null || true
    fi
}

main() {
    local action="${1:-status}"

    mkdir -p "${CACHE_DIR}/logs"

    case "${action}" in
        start)          start_gestures ;;
        stop)           stop_gestures ;;
        toggle)         toggle_gestures ;;
        restart)        stop_gestures; sleep 0.3; start_gestures ;;
        config)         create_gesture_config ;;
        status)
            if pgrep -x libinput-gestures &>/dev/null; then
                ok "libinput-gestures is running"
            else
                info "libinput-gestures is not running"
            fi
            ;;
        *)
            echo "Usage: gestures.sh [start|stop|toggle|restart|config|status]"
            exit 1
            ;;
    esac
}

main "$@"