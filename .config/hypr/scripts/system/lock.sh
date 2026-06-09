#!/bin/bash
# ╔═══════════════════════════════════════════════════════════════════════════════╗
# ║           ASH DOTFILES v3.0 — LOCK SCREEN                                  ║
# ║           Hyprlock with pre/post hooks, media pause, notifications          ║
# ╚═══════════════════════════════════════════════════════════════════════════════╝
#
# USAGE: lock.sh [MODE]
#
# MODES:
#   (none)   — Lock screen
#   suspend  — Lock and suspend
#   hibernate — Lock and hibernate
#   immediate — Lock without pre-hooks (fast)

set -euo pipefail

readonly CACHE_DIR="${HOME}/.cache/ash-dots"
readonly LOG_FILE="${CACHE_DIR}/logs/lock.log"
readonly LOCK_PID_FILE="/tmp/ash-hyprlock.pid"
readonly CONFIG_DIR="${HOME}/.config"

log()  { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "${LOG_FILE}" 2>/dev/null || true; }
info() { echo -e "  \033[96m→\033[0m $*"; }
ok()   { echo -e "  \033[92m✓\033[0m $*"; }
warn() { echo -e "  \033[93m⚠\033[0m $*" >&2; }

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 PRE-LOCK HOOKS
# ═══════════════════════════════════════════════════════════════════════════════

pre_lock_hooks() {
    info "Running pre-lock hooks..."

    # ── Pause media players ────────────────────────────────────────────────────
    if command -v playerctl &>/dev/null; then
        playerctl --all-players pause 2>/dev/null || true
        ok "Media paused"
    fi

    # ── Turn off microphone ────────────────────────────────────────────────────
    if command -v wpctl &>/dev/null; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 1 2>/dev/null || true
    fi

    # ── Stop screen recording if active ────────────────────────────────────────
    if pgrep -x wf-recorder &>/dev/null; then
        pkill -SIGINT wf-recorder 2>/dev/null || true
        warn "Screen recording stopped for lock"
    fi

    # ── Close sensitive applications (optional) ────────────────────────────────
    # Uncomment to close specific apps on lock:
    # pkill -x keepassxc 2>/dev/null || true

    # ── Dismiss notifications ──────────────────────────────────────────────────
    if command -v dunstctl &>/dev/null; then
        dunstctl close-all 2>/dev/null || true
    fi

    # ── Sync filesystem ───────────────────────────────────────────────────────
    sync 2>/dev/null || true

    log "INFO" "Pre-lock hooks complete"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔓 POST-LOCK HOOKS
# ═══════════════════════════════════════════════════════════════════════════════

post_lock_hooks() {
    info "Running post-lock hooks..."

    # ── Restore microphone ─────────────────────────────────────────────────────
    if command -v wpctl &>/dev/null; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ 0 2>/dev/null || true
    fi

    # ── Resume media (optional) ────────────────────────────────────────────────
    # Uncomment to auto-resume on unlock:
    # playerctl --all-players play 2>/dev/null || true

    # ── Send unlock notification ───────────────────────────────────────────────
    notify-send "🔓 Session Unlocked" \
        "Welcome back!" \
        --app-name="ASH Lock" \
        --expire-time=2000 \
        --icon=system-lock-screen-symbolic \
        2>/dev/null || true

    log "INFO" "Post-lock hooks complete — session unlocked"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🔒 LOCK SCREEN
# ═══════════════════════════════════════════════════════════════════════════════

do_lock() {
    # Check if already locked
    if pgrep -x hyprlock &>/dev/null; then
        info "Already locked"
        return 0
    fi

    log "INFO" "Locking screen..."

    # Run pre-lock hooks
    pre_lock_hooks

    # Small delay for hooks to complete
    sleep 0.1

    # Lock screen with hyprlock
    if command -v hyprlock &>/dev/null; then
        hyprlock 2>/dev/null
        local exit_code=$?

        if (( exit_code == 0 )); then
            # Successfully unlocked
            post_lock_hooks
        else
            log "WARN" "hyprlock exited with code ${exit_code}"
            post_lock_hooks
        fi
    else
        warn "hyprlock not found — trying swaylock"
        if command -v swaylock &>/dev/null; then
            swaylock \
                --color="${SURFACE0:-1e1e2e}" \
                --indicator \
                --indicator-radius=100 \
                --indicator-thickness=7 \
                --ring-color="${PRIMARY:-cba6f7}" \
                --key-hl-color="${SECONDARY:-89b4fa}" \
                --text-color="${TEXT:-cdd6f4}" \
                2>/dev/null
            post_lock_hooks
        else
            warn "No lock screen available (install hyprlock or swaylock)"
        fi
    fi
}

# ═══════════════════════════════════════════════════════════════════════════════
# 💤 SUSPEND WITH LOCK
# ═══════════════════════════════════════════════════════════════════════════════

do_suspend() {
    info "Lock and suspend..."
    pre_lock_hooks

    # Lock first, then suspend after hyprlock is shown
    if command -v hyprlock &>/dev/null; then
        hyprlock &
        local lock_pid=$!
        sleep 0.5

        # Suspend system
        systemctl suspend 2>/dev/null || \
        loginctl suspend 2>/dev/null || \
        echo mem | sudo tee /sys/power/state > /dev/null 2>&1 || \
        warn "Suspend failed — system may not support suspend"

        # Wait for hyprlock to exit after wake
        wait "${lock_pid}" 2>/dev/null || true
        post_lock_hooks
    else
        warn "hyprlock not found"
    fi

    log "INFO" "Suspend + lock complete"
}

# ═══════════════════════════════════════════════════════════════════════════════
# 🎯 MAIN
# ═══════════════════════════════════════════════════════════════════════════════

main() {
    local mode="${1:-lock}"

    mkdir -p "${CACHE_DIR}/logs"

    # Source colors if available
    local colors_file="${CACHE_DIR}/colors/current.sh"
    if [[ -f "${colors_file}" ]]; then
        # shellcheck source=/dev/null
        source "${colors_file}" 2>/dev/null || true
    fi

    case "${mode}" in
        lock | "")
            do_lock
            ;;

        suspend)
            do_suspend
            ;;

        hibernate)
            info "Lock and hibernate..."
            pre_lock_hooks

            if command -v hyprlock &>/dev/null; then
                hyprlock &
                sleep 0.5
                systemctl hibernate 2>/dev/null || warn "Hibernate failed"
                wait 2>/dev/null || true
                post_lock_hooks
            fi
            ;;

        immediate)
            # Skip pre-lock hooks for fast lock
            if command -v hyprlock &>/dev/null; then
                hyprlock 2>/dev/null
                post_lock_hooks
            fi
            ;;

        status)
            if pgrep -x hyprlock &>/dev/null; then
                echo "locked"
            else
                echo "unlocked"
            fi
            ;;

        *)
            echo "Usage: lock.sh [lock|suspend|hibernate|immediate|status]"
            exit 1
            ;;
    esac
}

main "$@"